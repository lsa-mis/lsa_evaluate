# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EntryAnswerDisplayValues do
  let(:container) { create(:container) }
  let(:profile) { create(:profile, pen_name: 'Ink', degree: 'BA') }
  let(:pen_name_question) { container.application_questions.find_by!(system_key: 'pen_name') }
  let(:degree_question) { container.application_questions.find_by!(system_key: 'degree') }
  let(:custom_question) do
    create(:application_question, container:, key: 'workshop', label: 'Workshop', field_type: 'string')
  end

  it 'returns prefill values when no answers were submitted' do
    values = described_class.for(profile:, questions: [pen_name_question, degree_question])

    expect(values[pen_name_question.id]).to eq('Ink')
    expect(values[degree_question.id]).to eq('BA')
  end

  it 'overrides prefill with submitted answers' do
    values = described_class.for(
      profile:,
      questions: [pen_name_question],
      submitted_answers: { pen_name_question.id.to_s => 'A. Poet' }
    )

    expect(values[pen_name_question.id]).to eq('A. Poet')
  end

  it 'clears a prefilled value when the submitted answer is blank' do
    values = described_class.for(
      profile:,
      questions: [pen_name_question],
      submitted_answers: { pen_name_question.id.to_s => '' }
    )

    expect(values).not_to have_key(pen_name_question.id)
  end

  it 'prefers submitted answers over admin defaults for custom questions' do
    custom_question.update!(options: { 'default_value' => 'Afternoon' })

    values = described_class.for(
      profile:,
      questions: [custom_question],
      submitted_answers: { custom_question.id.to_s => 'Morning' }
    )

    expect(values[custom_question.id]).to eq('Morning')
  end

  it 'falls back to admin defaults when no answer was submitted for a custom question' do
    custom_question.update!(options: { 'default_value' => 'Afternoon' })

    values = described_class.for(profile:, questions: [custom_question])

    expect(values[custom_question.id]).to eq('Afternoon')
  end

  it 'normalizes boolean submitted answers' do
    campus_employee = container.application_questions.find_by!(system_key: 'campus_employee')

    values = described_class.for(
      profile:,
      questions: [campus_employee],
      submitted_answers: { campus_employee.id.to_s => '0' }
    )

    expect(values[campus_employee.id]).to be(false)
  end

  it 'normalizes select_with_other submitted answers' do
    referral_question = container.application_questions.find_by!(system_key: 'contest_referral_source')

    values = described_class.for(
      profile:,
      questions: [referral_question],
      submitted_answers: {
        referral_question.id.to_s => { 'choice' => 'Other', 'other' => 'Poster' }
      }
    )

    expect(values[referral_question.id]).to eq('choice' => 'Other', 'other' => 'Poster')
  end

  it 'does not override prefill when a question key is absent from submitted answers' do
    profile.update!(campus_employee: true)
    campus_employee = container.application_questions.find_by!(system_key: 'campus_employee')

    values = described_class.for(
      profile:,
      questions: [campus_employee],
      submitted_answers: { pen_name_question.id.to_s => 'A. Poet' }
    )

    expect(values[campus_employee.id]).to be(true)
  end
end
