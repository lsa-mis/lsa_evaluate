# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EntryAnswerParamNormalizer do
  let(:container) { create(:container) }

  def question(field_type, **attrs)
    create(:application_question, container:, field_type:, **attrs)
  end

  describe '.normalize' do
    it 'returns nil for blank boolean input so required Yes/No can fail open' do
      q = container.application_questions.find_by!(system_key: 'campus_employee')

      expect(described_class.normalize(q, nil)).to be_nil
      expect(described_class.normalize(q, '')).to be_nil
    end

    it 'casts truthy and falsey boolean strings' do
      q = container.application_questions.find_by!(system_key: 'campus_employee')

      expect(described_class.normalize(q, '1')).to be(true)
      expect(described_class.normalize(q, '0')).to be(false)
    end

    it 'slices select_with_other hashes and ActionController::Parameters' do
      q = container.application_questions.find_by!(system_key: 'contest_referral_source')
      params = ActionController::Parameters.new('choice' => 'Other', 'other' => 'Flyer', 'extra' => 'drop')

      expect(described_class.normalize(q, params)).to eq('choice' => 'Other', 'other' => 'Flyer')
      expect(described_class.normalize(q, { choice: 'Faculty', other: '' })).to eq(
        'choice' => 'Faculty', 'other' => ''
      )
    end

    it 'wraps a bare select_with_other string as a choice hash' do
      q = container.application_questions.find_by!(system_key: 'contest_referral_source')

      expect(described_class.normalize(q, 'Website')).to eq('choice' => 'Website')
    end

    it 'casts campus and school values to integers and blanks to nil' do
      campus_q = container.application_questions.find_by!(system_key: 'campus')
      school_q = container.application_questions.find_by!(system_key: 'school')

      expect(described_class.normalize(campus_q, '42')).to eq(42)
      expect(described_class.normalize(school_q, '')).to be_nil
    end

    it 'preserves present date/string values and nils blanks' do
      date_q = question('date', key: 'deadline', label: 'Deadline')
      text_q = question('string', key: 'nickname', label: 'Nickname')

      expect(described_class.normalize(date_q, '2026-09-01')).to eq('2026-09-01')
      expect(described_class.normalize(date_q, '')).to be_nil
      expect(described_class.normalize(text_q, 'Ada')).to eq('Ada')
      expect(described_class.normalize(text_q, '   ')).to be_nil
    end
  end
end
