# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EntryAnswer do
  let(:container) { create(:container) }
  let(:entry) { create(:entry) }

  def build_answer(question:, value:)
    described_class.new(entry:, application_question: question, value:)
  end

  describe '#blank_answer?' do
    it 'treats nil boolean values as blank' do
      question = container.application_questions.find_by!(system_key: 'campus_employee')
      expect(build_answer(question:, value: nil)).to be_blank_answer
    end

    it 'does not treat false boolean values as blank' do
      question = container.application_questions.find_by!(system_key: 'campus_employee')
      expect(build_answer(question:, value: false)).not_to be_blank_answer
    end

    it 'treats select_with_other Other without free text as blank' do
      question = container.application_questions.find_by!(system_key: 'contest_referral_source')
      answer = build_answer(question:, value: { 'choice' => 'Other', 'other' => '' })
      expect(answer).to be_blank_answer
    end

    it 'does not treat a normal select_with_other choice as blank' do
      question = container.application_questions.find_by!(system_key: 'contest_referral_source')
      answer = build_answer(question:, value: { 'choice' => 'Faculty' })
      expect(answer).not_to be_blank_answer
    end

    it 'treats blank string answers as blank' do
      question = container.application_questions.find_by!(system_key: 'pen_name')
      expect(build_answer(question:, value: '')).to be_blank_answer
    end
  end

  describe '#agreement_accepted?' do
    let(:question) { container.application_questions.find_by!(system_key: 'accepted_financial_aid_notice') }

    it 'returns true only for truthy values' do
      expect(build_answer(question:, value: true)).to be_agreement_accepted
      expect(build_answer(question:, value: '1')).to be_agreement_accepted
      expect(build_answer(question:, value: false)).not_to be_agreement_accepted
      expect(build_answer(question:, value: '0')).not_to be_agreement_accepted
    end
  end

  describe '#display_value' do
    it 'renders boolean answers as Yes/No' do
      question = container.application_questions.find_by!(system_key: 'campus_employee')
      expect(build_answer(question:, value: true).display_value).to eq('Yes')
      expect(build_answer(question:, value: false).display_value).to eq('No')
    end

    it 'renders campus and school labels when records exist' do
      campus = create(:campus, campus_descr: 'Dearborn')
      school = create(:school, name: 'LSA')
      campus_q = container.application_questions.find_by!(system_key: 'campus')
      school_q = container.application_questions.find_by!(system_key: 'school')

      expect(build_answer(question: campus_q, value: campus.id).display_value).to eq('Dearborn')
      expect(build_answer(question: school_q, value: school.id).display_value).to eq('LSA')
    end

    it 'renders select_with_other Other answers with free text' do
      question = container.application_questions.find_by!(system_key: 'contest_referral_source')
      answer = build_answer(question:, value: { 'choice' => 'Other', 'other' => 'Bus ad' })
      expect(answer.display_value).to eq('Other: Bus ad')
    end

    it 'falls back to the raw campus/school id when the record is missing' do
      campus_q = container.application_questions.find_by!(system_key: 'campus')
      expect(build_answer(question: campus_q, value: 999_999).display_value).to eq('999999')
    end
  end

  describe 'uniqueness' do
    it 'rejects a second answer for the same entry and question' do
      question = container.application_questions.find_by!(system_key: 'pen_name')
      described_class.create!(entry:, application_question: question, value: 'One')
      duplicate = build_answer(question:, value: 'Two')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:application_question_id]).to be_present
    end
  end
end
