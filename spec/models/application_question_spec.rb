# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationQuestion do
  let(:container) { create(:container) }

  describe 'key validations' do
    it 'accepts a short descriptive slug' do
      question = build(:application_question, container:, key: 'workshop_title')
      expect(question).to be_valid
    end

    it 'normalizes human-readable input into a slug' do
      question = build(:application_question, container:, key: 'Workshop Title')
      expect(question).to be_valid
      expect(question.key).to eq('workshop_title')
    end

    it 'generates a key from the label when none is provided' do
      question = build(:application_question, container:, key: nil, label: 'Workshop Title')
      expect(question).to be_valid
      expect(question.key).to eq('workshop_title')
    end

    it 'avoids reserved system keys when generating from a label' do
      question = build(:application_question, container:, key: nil, label: 'Degree')
      expect(question).to be_valid
      expect(question.key).to eq('degree_2')
    end

    it 'suffixes generated keys that already exist in the collection' do
      create(:application_question, container:, key: 'workshop_title', label: 'Workshop title')
      question = build(:application_question, container:, key: nil, label: 'Workshop Title')
      expect(question).to be_valid
      expect(question.key).to eq('workshop_title_2')
    end

    it 'does not regenerate an existing key when the label changes' do
      question = create(:application_question, container:, key: 'workshop_title', label: 'Workshop title')
      question.label = 'Preferred workshop'
      expect(question).to be_valid
      expect(question.key).to eq('workshop_title')
    end

    it 'rejects a key that starts with a number' do
      question = build(:application_question, container:, key: '1workshop')
      expect(question).not_to be_valid
      expect(question.errors[:key]).to include(
        'must start with a letter and use lowercase letters, numbers, and single underscores (e.g. workshop_title)'
      )
    end

    it 'rejects a reserved system key for custom questions' do
      question = build(:application_question, container:, key: 'degree')
      expect(question).not_to be_valid
      expect(question.errors[:key]).to include('is reserved for a built-in system question')
    end

    it 'rejects a duplicate custom key in the same collection' do
      create(:application_question, container:, key: 'workshop_title')
      duplicate = build(:application_question, container:, key: 'workshop_title')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:key]).to include('has already been taken')
    end
  end

  describe 'immutability and lifecycle guards' do
    let(:question) { container.application_questions.find_by!(system_key: 'degree') }
    let(:contest_description) { create(:contest_description, :active, container:) }
    let!(:contest_instance) { create(:contest_instance, contest_description:) }

    it 'does not allow changing field_type after create' do
      question.field_type = 'text'
      expect(question).not_to be_valid
      expect(question.errors[:field_type]).to include('cannot be changed after create')
    end

    it 'does not allow changing system_key after create' do
      question.system_key = 'pen_name'
      expect(question).not_to be_valid
      expect(question.errors[:system_key]).to include('cannot be changed after create')
    end

    it 'blocks deactivating a system question required by an active contest instance' do
      ApplicationQuestionRequirement.create!(
        application_question: question,
        requireable: contest_instance,
        status: 'required'
      )

      question.active = false
      expect(question).not_to be_valid
      expect(question.errors[:active]).to include(
        'cannot be deactivated while required by an active contest instance'
      )
    end

    it 'blocks deleting a question that already has answers' do
      entry = create(:entry, contest_instance:)
      EntryAnswer.create!(entry:, application_question: question, value: 'MFA')

      expect(question.destroy).to be(false)
      expect(question.errors[:base].join).to match(/entry answers/i)
      expect(described_class.exists?(question.id)).to be(true)
    end
  end
end
