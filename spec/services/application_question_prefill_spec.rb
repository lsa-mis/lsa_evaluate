# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationQuestionPrefill do
  let(:container_a) { create(:container) }
  let(:container_b) { create(:container) }
  let(:profile) { create(:profile, degree: 'BA', pen_name: 'Ink') }
  let(:question_a) { container_a.application_questions.find_by!(system_key: 'degree') }
  let(:question_b) { container_b.application_questions.find_by!(system_key: 'degree') }
  let(:custom_a) do
    create(:application_question, container: container_a, key: 'workshop', label: 'Workshop', field_type: 'string')
  end
  let(:custom_b) do
    create(:application_question, container: container_b, key: 'workshop', label: 'Workshop', field_type: 'string')
  end

  it 'prefills system_key answers across containers from the newest entry answer' do
    entry = create(:entry, profile:)
    EntryAnswer.create!(entry:, application_question: question_a, value: 'MFA')

    values = described_class.for(profile:, questions: [ question_b ])
    expect(values[question_b.id]).to eq('MFA')
  end

  it 'falls back to profile attributes for system keys when no entry answers exist' do
    values = described_class.for(profile:, questions: [ question_b ])
    expect(values[question_b.id]).to eq('BA')
  end

  it 'does not prefill custom questions across containers' do
    entry = create(:entry, profile:)
    EntryAnswer.create!(entry:, application_question: custom_a, value: 'Morning')

    values = described_class.for(profile:, questions: [ custom_b ])
    expect(values[custom_b.id]).to be_nil
  end

  it 'prefills custom questions within the same container' do
    entry = create(:entry, profile:)
    EntryAnswer.create!(entry:, application_question: custom_a, value: 'Morning')

    values = described_class.for(profile:, questions: [ custom_a ])
    expect(values[custom_a.id]).to eq('Morning')
  end

  it 'ignores answers from soft-deleted entries when prefilling' do
    deleted_entry = create(:entry, profile:, deleted: true)
    EntryAnswer.create!(entry: deleted_entry, application_question: question_a, value: 'MFA')

    values = described_class.for(profile:, questions: [ question_b ])
    expect(values[question_b.id]).to eq('BA')
  end

  it 'prefills from the newest non-deleted entry when multiple answers exist' do
    older = create(:entry, profile:, created_at: 2.days.ago)
    newer = create(:entry, profile:, created_at: 1.day.ago)
    EntryAnswer.create!(entry: older, application_question: question_a, value: 'BA')
    EntryAnswer.create!(entry: newer, application_question: question_a, value: 'MFA')

    values = described_class.for(profile:, questions: [ question_b ])
    expect(values[question_b.id]).to eq('MFA')
  end

  it 'prefills false boolean values from the profile' do
    profile.update!(campus_employee: false, receiving_financial_aid: false)
    campus_employee = container_a.application_questions.find_by!(system_key: 'campus_employee')
    receiving_financial_aid = container_a.application_questions.find_by!(system_key: 'receiving_financial_aid')

    values = described_class.for(profile:, questions: [ campus_employee, receiving_financial_aid ])

    expect(values[campus_employee.id]).to be(false)
    expect(values[receiving_financial_aid.id]).to be(false)
  end

  it 'prefills true boolean values from the profile' do
    profile.update!(campus_employee: true, receiving_financial_aid: true)
    campus_employee = container_a.application_questions.find_by!(system_key: 'campus_employee')

    values = described_class.for(profile:, questions: [ campus_employee ])
    expect(values[campus_employee.id]).to be(true)
  end

  it 'prefills custom questions from admin-configured defaults when no prior answer exists' do
    custom_a.update!(options: { 'default_value' => 'Afternoon' })

    values = described_class.for(profile:, questions: [ custom_a ])
    expect(values[custom_a.id]).to eq('Afternoon')
  end

  it 'prefers prior answers over admin defaults for custom questions' do
    custom_a.update!(options: { 'default_value' => 'Afternoon' })
    entry = create(:entry, profile:)
    EntryAnswer.create!(entry:, application_question: custom_a, value: 'Morning')

    values = described_class.for(profile:, questions: [ custom_a ])
    expect(values[custom_a.id]).to eq('Morning')
  end

  describe 'school and department class-level prefills' do
    let(:graduate_level) { create(:class_level, name: 'Graduate') }
    let(:undergraduate_level) { create(:class_level, name: 'First year') }
    let(:rackham) { create(:school, name: School::RACKHAM_NAME) }
    let(:other_school) { create(:school, name: 'LSA') }
    let(:school_question) { container_a.application_questions.find_by!(system_key: 'school') }
    let(:department_question) { container_a.application_questions.find_by!(system_key: 'department') }

    it 'defaults school to Rackham for graduates with no prior school' do
      rackham
      profile.update!(class_level: graduate_level, school: nil)

      values = described_class.for(profile:, questions: [ school_question ])
      expect(values[school_question.id]).to eq(rackham.id)
    end

    it 'does not overwrite an existing school with Rackham' do
      rackham
      profile.update!(class_level: graduate_level, school: other_school)

      values = described_class.for(profile:, questions: [ school_question ])
      expect(values[school_question.id]).to eq(other_school.id)
    end

    it 'does not default school to Rackham for undergraduates' do
      rackham
      profile.update!(class_level: undergraduate_level, school: nil)

      values = described_class.for(profile:, questions: [ school_question ])
      expect(values[school_question.id]).to be_nil
    end

    it 'maps legacy profile department strings onto select_with_other values' do
      profile.update!(department: 'English')

      values = described_class.for(profile:, questions: [ department_question ])
      expect(values[department_question.id]).to eq('choice' => 'English Language and Literature')
    end

    it 'maps unknown legacy department strings to Other' do
      profile.update!(department: 'Astrophysics')

      values = described_class.for(profile:, questions: [ department_question ])
      expect(values[department_question.id]).to eq('choice' => 'Other', 'other' => 'Astrophysics')
    end
  end
end
