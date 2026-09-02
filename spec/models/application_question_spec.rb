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

    it 'prefixes generated keys that would otherwise start with a number' do
      question = build(:application_question, container:, key: nil, label: '2024 Workshop')
      expect(question).to be_valid
      expect(question.key).to eq('q_2024_workshop')
    end

    it 'falls back to a generic key when the label has no usable characters' do
      question = build(:application_question, container:, key: nil, label: '!!!')
      expect(question).to be_valid
      expect(question.key).to eq('custom_question')
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

  describe 'field type labels' do
    it 'uses plain-language names for answer types' do
      question = build(:application_question, container:, field_type: 'select_with_other')

      expect(question.field_type_label).to eq('Dropdown with Other')
      expect(described_class.field_type_options).to include(
        [ 'Short answer (one line)', 'string' ],
        [ 'Paragraph', 'text' ],
        [ 'Yes / no', 'boolean' ],
        [ 'Dropdown (choose one)', 'select' ]
      )
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

  describe 'default position' do
    it 'assigns the next position when none is provided' do
      max_position = container.application_questions.maximum(:position)
      question = create(:application_question, container:, position: nil, key: 'workshop_title')

      expect(question.position).to eq(max_position + 1)
    end
  end

  describe '#requires_acceptance?' do
    it 'treats system agreement questions as requiring acceptance' do
      agreement = container.application_questions.find_by!(system_key: 'accepted_financial_aid_notice')
      sole_author = container.application_questions.find_by!(system_key: 'submission_sole_author')
      campus_employee = container.application_questions.find_by!(system_key: 'campus_employee')

      expect(agreement).to be_requires_acceptance
      expect(sole_author).to be_requires_acceptance
      expect(campus_employee).not_to be_requires_acceptance
    end

    it 'supports requires_acceptance on custom boolean questions' do
      question = create(
        :application_question,
        container:,
        field_type: 'boolean',
        label: 'I certify this work',
        key: 'certify_work',
        options: { 'requires_acceptance' => true }
      )

      expect(question).to be_requires_acceptance
    end
  end

  describe 'default values' do
    it 'accepts a valid select default from choices' do
      question = build(
        :application_question,
        container:,
        field_type: 'select',
        options: { 'choices' => %w[Poetry Fiction], 'default_value' => 'Poetry' }
      )

      expect(question).to be_valid
      expect(question.default_answer_value).to eq('Poetry')
    end

    it 'rejects a select default that is not in choices' do
      question = build(
        :application_question,
        container:,
        field_type: 'select',
        options: { 'choices' => %w[Poetry Fiction], 'default_value' => 'Drama' }
      )

      expect(question).not_to be_valid
      expect(question.errors[:base]).to include('default value must be one of the dropdown choices')
    end

    it 'accepts a valid date default' do
      question = build(
        :application_question,
        container:,
        field_type: 'date',
        options: { 'default_value' => '2026-05-01' }
      )

      expect(question).to be_valid
      expect(question.default_answer_value).to eq('2026-05-01')
    end

    it 'rejects an invalid date default' do
      question = build(
        :application_question,
        container:,
        field_type: 'date',
        options: { 'default_value' => 'not-a-date' }
      )

      expect(question).not_to be_valid
      expect(question.errors[:base]).to include('default value must be a valid date')
    end

    it 'accepts a valid campus default' do
      campus = create(:campus)
      question = build(
        :application_question,
        container:,
        field_type: 'campus',
        options: { 'default_value' => campus.id }
      )

      expect(question).to be_valid
      expect(question.default_answer_value).to eq(campus.id)
    end

    it 'accepts a valid boolean default' do
      question = build(
        :application_question,
        container:,
        field_type: 'boolean',
        options: { 'default_value' => true }
      )

      expect(question).to be_valid
      expect(question.default_answer_value).to be(true)
    end

    it 'accepts a valid select_with_other default hash' do
      question = build(
        :application_question,
        container:,
        field_type: 'select_with_other',
        options: {
          'choices' => %w[Poetry Fiction Other],
          'default_value' => { 'choice' => 'Other', 'other' => 'Spoken word' }
        }
      )

      expect(question).to be_valid
      expect(question.default_answer_value).to eq('choice' => 'Other', 'other' => 'Spoken word')
    end

    it 'normalizes a plain-string select_with_other default into a choice hash' do
      question = build(
        :application_question,
        container:,
        field_type: 'select_with_other',
        options: { 'choices' => %w[Poetry Fiction Other], 'default_value' => 'Poetry' }
      )

      expect(question).to be_valid
      expect(question.options['default_value']).to eq('choice' => 'Poetry')
      expect(question.default_answer_value).to eq('choice' => 'Poetry')
    end

    it 'rejects a select_with_other default whose choice is not in the list' do
      question = build(
        :application_question,
        container:,
        field_type: 'select_with_other',
        options: {
          'choices' => %w[Poetry Fiction Other],
          'default_value' => { 'choice' => 'Drama' }
        }
      )

      expect(question).not_to be_valid
      expect(question.errors[:base]).to include('default value must be one of the dropdown choices')
    end

    it 'rejects select_with_other other-text when the choice is not Other' do
      question = build(
        :application_question,
        container:,
        field_type: 'select_with_other',
        options: {
          'choices' => %w[Poetry Fiction Other],
          'default_value' => { 'choice' => 'Poetry', 'other' => 'should not be here' }
        }
      )

      expect(question).not_to be_valid
      expect(question.errors[:base]).to include('default other text is only allowed when Other is selected')
    end

    it 'accepts a valid school default' do
      school = create(:school)
      question = build(
        :application_question,
        container:,
        field_type: 'school',
        options: { 'default_value' => school.id }
      )

      expect(question).to be_valid
      expect(question.default_answer_value).to eq(school.id)
    end

    it 'rejects an unknown school default' do
      question = build(
        :application_question,
        container:,
        field_type: 'school',
        options: { 'default_value' => 0 }
      )

      expect(question).not_to be_valid
      expect(question.errors[:base]).to include('default value must be a valid school or college')
    end

    it 'rejects an unknown campus default' do
      question = build(
        :application_question,
        container:,
        field_type: 'campus',
        options: { 'default_value' => 0 }
      )

      expect(question).not_to be_valid
      expect(question.errors[:base]).to include('default value must be a valid campus')
    end

    it 'strips default values from system questions' do
      question = container.application_questions.find_by!(system_key: 'degree')
      question.options = { 'default_value' => 'BA' }

      expect(question).to be_valid
      expect(question.options).not_to have_key('default_value')
    end
  end

  describe '#applies_to_class_level?' do
    let(:graduate) { build(:class_level, name: 'Graduate') }
    let(:undergraduate) { build(:class_level, name: 'First year') }
    let(:department_question) { container.application_questions.find_by!(system_key: 'department') }
    let(:major_question) { container.application_questions.find_by!(system_key: 'major') }
    let(:degree_question) { container.application_questions.find_by!(system_key: 'degree') }

    it 'limits department to graduate students and major to undergraduates' do
      expect(department_question.applies_to_class_level?(graduate)).to be(true)
      expect(department_question.applies_to_class_level?(undergraduate)).to be(false)
      expect(major_question.applies_to_class_level?(undergraduate)).to be(true)
      expect(major_question.applies_to_class_level?(graduate)).to be(false)
    end

    it 'does not limit other system questions by class level' do
      expect(degree_question.applies_to_class_level?(graduate)).to be(true)
      expect(degree_question.applies_to_class_level?(undergraduate)).to be(true)
    end
  end
end
