# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EffectiveApplicationQuestions do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container:) }
  let(:contest_instance) { create(:contest_instance, contest_description:) }
  let!(:degree_question) { container.application_questions.find_by!(system_key: 'degree') }
  let!(:pen_name_question) { container.application_questions.find_by!(system_key: 'pen_name') }

  before do
    ApplicationQuestionRequirement.create!(
      application_question: degree_question,
      requireable: container,
      status: 'required'
    )
    ApplicationQuestionRequirement.create!(
      application_question: pen_name_question,
      requireable: container,
      status: 'required'
    )
  end

  it 'returns container requirements by default' do
    result = described_class.for(contest_instance)
    expect(result.map { |eq| eq.question.system_key }).to include('degree', 'pen_name')
    expect(result.find { |eq| eq.question.system_key == 'degree' }.source_level).to eq('Container')
  end

  it 'allows contest description to override status' do
    ApplicationQuestionRequirement.create!(
      application_question: degree_question,
      requireable: contest_description,
      status: 'optional'
    )

    result = described_class.for(contest_instance)
    degree = result.find { |eq| eq.question.system_key == 'degree' }
    expect(degree.status).to eq('optional')
    expect(degree.source_level).to eq('ContestDescription')
  end

  it 'allows contest instance to turn off a parent required question' do
    ApplicationQuestionRequirement.create!(
      application_question: degree_question,
      requireable: contest_instance,
      status: 'off'
    )

    result = described_class.for(contest_instance)
    expect(result.map { |eq| eq.question.system_key }).not_to include('degree')
    expect(result.map { |eq| eq.question.system_key }).to include('pen_name')
  end
end
