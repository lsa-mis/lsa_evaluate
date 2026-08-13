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
end
