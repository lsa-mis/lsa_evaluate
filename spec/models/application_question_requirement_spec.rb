# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationQuestionRequirement do
  let(:container) { create(:container) }
  let(:question) { container.application_questions.find_by!(system_key: 'degree') }
  let(:contest_description) { create(:contest_description, :active, container:) }
  let(:contest_instance) { create(:contest_instance, contest_description:) }

  it 'accepts required/optional/off statuses on container, description, and instance' do
    expect(
      described_class.create!(application_question: question, requireable: container, status: 'required')
    ).to be_persisted
    expect(
      described_class.create!(application_question: question, requireable: contest_description, status: 'optional')
    ).to be_persisted
    expect(
      described_class.create!(application_question: question, requireable: contest_instance, status: 'off')
    ).to be_persisted
  end

  it 'rejects an invalid status' do
    requirement = described_class.new(
      application_question: question,
      requireable: container,
      status: 'maybe'
    )
    expect(requirement).not_to be_valid
    expect(requirement.errors[:status]).to be_present
  end

  it 'rejects a question from a different container' do
    other_container = create(:container)
    other_question = other_container.application_questions.find_by!(system_key: 'degree')

    requirement = described_class.new(
      application_question: other_question,
      requireable: contest_instance,
      status: 'required'
    )

    expect(requirement).not_to be_valid
    expect(requirement.errors[:application_question]).to include('must belong to the same container')
  end

  it 'enforces uniqueness per question and requireable' do
    described_class.create!(application_question: question, requireable: container, status: 'required')
    duplicate = described_class.new(
      application_question: question,
      requireable: container,
      status: 'optional'
    )
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:application_question_id]).to be_present
  end
end
