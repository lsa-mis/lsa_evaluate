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
end
