# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Application questions migration', type: :model do
  it 'seeds system questions when a container is created' do
    container = create(:container)
    expect(container.application_questions.system.count).to eq(ApplicationQuestion::SYSTEM_QUESTION_DEFINITIONS.size)
  end

  it 'migrates legacy require_* flags into instance requirements' do
    contest_instance = create(:contest_instance, require_pen_name: true, require_finaid_info: true)
    container = contest_instance.contest_description.container
    pen_name = container.application_questions.find_by!(system_key: 'pen_name')

    ApplicationQuestionRequirement.find_or_create_by!(
      application_question: pen_name,
      requireable: contest_instance
    ) { |req| req.status = 'required' }

    expect(
      contest_instance.application_question_requirements.where(application_question: pen_name, status: 'required')
    ).to exist
  end
end
