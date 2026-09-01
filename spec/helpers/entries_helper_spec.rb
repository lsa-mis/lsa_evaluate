# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EntriesHelper, type: :helper do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }
  let(:entry) { create(:entry, contest_instance: contest_instance) }
  let(:pen_name_question) { container.application_questions.find_by!(system_key: 'pen_name') }

  describe '#entry_answer_display' do
    it 'returns an em dash when the question is missing' do
      expect(helper.entry_answer_display(entry, 'missing_system_key')).to eq('—')
    end

    it 'returns an em dash when no answer exists' do
      expect(helper.entry_answer_display(entry, pen_name_question)).to eq('—')
    end

    it 'returns the display value for a system key answer' do
      EntryAnswer.create!(entry: entry, application_question: pen_name_question, value: 'A. Poet')
      expect(helper.entry_answer_display(entry, 'pen_name')).to eq('A. Poet')
    end

    it 'returns the display value when given an ApplicationQuestion' do
      EntryAnswer.create!(entry: entry, application_question: pen_name_question, value: 'A. Poet')
      expect(helper.entry_answer_display(entry, pen_name_question)).to eq('A. Poet')
    end
  end

  describe '#effective_question_headers' do
    it 'returns only questions required or optional for the contest instance' do
      ApplicationQuestionRequirement.create!(
        application_question: pen_name_question,
        requireable: contest_instance,
        status: 'required'
      )

      headers = helper.effective_question_headers(contest_instance)

      expect(headers).to include(pen_name_question)
      expect(headers.map(&:system_key)).not_to include('degree')
    end
  end
end
