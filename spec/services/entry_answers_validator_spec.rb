# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EntryAnswersValidator do
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container:) }
  let(:contest_instance) { create(:contest_instance, contest_description:) }
  let(:category) { create(:category, kind: 'ecat') }
  let(:profile) { create(:profile) }
  let(:entry) { build(:entry, category:, contest_instance:, profile:, pen_name: nil) }

  def require_question!(question)
    requirement = ApplicationQuestionRequirement.find_or_initialize_by(
      application_question: question,
      requireable: contest_instance
    )
    requirement.status = 'required'
    requirement.save!
  end

  def optional_question!(question)
    requirement = ApplicationQuestionRequirement.find_or_initialize_by(
      application_question: question,
      requireable: contest_instance
    )
    requirement.status = 'optional'
    requirement.save!
  end

  def validate!(answers_params)
    effective = EffectiveApplicationQuestions.for(contest_instance)
    described_class.new(entry:, effective_questions: effective, answers_params:).call
  end

  describe 'required string answers' do
    let!(:pen_name_question) { container.application_questions.find_by!(system_key: 'pen_name') }

    before { require_question!(pen_name_question) }

    it 'rejects a blank required answer' do
      expect(validate!({})).to be(false)
      expect(entry.errors[:base].join).to include("can't be blank")
    end

    it 'accepts a present required answer and builds EntryAnswer records' do
      validator = described_class.new(
        entry:,
        effective_questions: EffectiveApplicationQuestions.for(contest_instance),
        answers_params: { pen_name_question.id.to_s => 'A. Poet' }
      )

      expect(validator.call).to be(true)
      expect(validator.built_answers.size).to eq(1)
      expect(validator.built_answers.first.value).to eq('A. Poet')
    end

    it 'looks up answers by integer question id keys' do
      expect(validate!(pen_name_question.id => 'Ink')).to be(true)
    end
  end

  describe 'agreement questions' do
    let!(:agreement_question) do
      container.application_questions.find_by!(system_key: 'accepted_financial_aid_notice')
    end

    before { require_question!(agreement_question) }

    it 'rejects when the agreement is not accepted' do
      expect(validate!(agreement_question.id.to_s => '0')).to be(false)
      expect(entry.errors[:base].join).to include('must be accepted')
    end

    it 'accepts when the agreement is true' do
      expect(validate!(agreement_question.id.to_s => '1')).to be(true)
    end
  end

  describe 'boolean normalization' do
    let!(:boolean_question) { container.application_questions.find_by!(system_key: 'campus_employee') }

    before { optional_question!(boolean_question) }

    it 'casts truthy values to true' do
      validator = described_class.new(
        entry:,
        effective_questions: EffectiveApplicationQuestions.for(contest_instance),
        answers_params: { boolean_question.id.to_s => '1' }
      )
      validator.call
      expect(validator.built_answers.first.value).to be(true)
    end

    it 'casts blank-ish boolean input to false rather than nil' do
      validator = described_class.new(
        entry:,
        effective_questions: EffectiveApplicationQuestions.for(contest_instance),
        answers_params: { boolean_question.id.to_s => '' }
      )
      validator.call
      expect(validator.built_answers.first.value).to be(false)
    end

    it 'defaults optional missing boolean answers to false' do
      validator = described_class.new(
        entry:,
        effective_questions: EffectiveApplicationQuestions.for(contest_instance),
        answers_params: {}
      )
      validator.call
      expect(validator.built_answers.find { |a| a.application_question_id == boolean_question.id }.value).to be(false)
    end

    it 'rejects a missing answer for a required non-agreement boolean' do
      require_question!(boolean_question)

      expect(validate!({})).to be(false)
      expect(entry.errors[:base].join).to include("can't be blank")
    end

    it 'accepts an explicit No for a required non-agreement boolean' do
      require_question!(boolean_question)

      expect(validate!(boolean_question.id.to_s => '0')).to be(true)
    end
  end

  describe 'select_with_other normalization' do
    let!(:referral_question) do
      container.application_questions.find_by!(system_key: 'contest_referral_source')
    end

    before { require_question!(referral_question) }

    it 'keeps choice/other hash values' do
      validator = described_class.new(
        entry:,
        effective_questions: EffectiveApplicationQuestions.for(contest_instance),
        answers_params: {
          referral_question.id.to_s => { 'choice' => 'Other', 'other' => 'Poster' }
        }
      )

      expect(validator.call).to be(true)
      expect(validator.built_answers.first.value).to eq('choice' => 'Other', 'other' => 'Poster')
    end

    it 'wraps a scalar value as choice' do
      validator = described_class.new(
        entry:,
        effective_questions: EffectiveApplicationQuestions.for(contest_instance),
        answers_params: { referral_question.id.to_s => 'Faculty' }
      )

      expect(validator.call).to be(true)
      expect(validator.built_answers.first.value).to eq('choice' => 'Faculty')
    end

    it 'rejects Other without a free-text other value' do
      expect(
        validate!(referral_question.id.to_s => { 'choice' => 'Other', 'other' => '' })
      ).to be(false)
      expect(entry.errors[:base].join).to include("can't be blank")
    end

    it 'normalizes unpermitted ActionController::Parameters' do
      params = ActionController::Parameters.new('choice' => 'Friend', 'other' => '')
      validator = described_class.new(
        entry:,
        effective_questions: EffectiveApplicationQuestions.for(contest_instance),
        answers_params: { referral_question.id.to_s => params }
      )

      expect(validator.call).to be(true)
      expect(validator.built_answers.first.value).to eq('choice' => 'Friend', 'other' => '')
    end

    it 'rejects blank choice from unpermitted ActionController::Parameters' do
      params = ActionController::Parameters.new('choice' => '', 'other' => '')
      expect(validate!(referral_question.id.to_s => params)).to be(false)
      expect(entry.errors[:base].join).to include("can't be blank")
    end
  end

  describe 'campus and school normalization' do
    let!(:campus_question) { container.application_questions.find_by!(system_key: 'campus') }
    let!(:school_question) { container.application_questions.find_by!(system_key: 'school') }

    before do
      optional_question!(campus_question)
      optional_question!(school_question)
    end

    it 'casts campus and school ids to integers' do
      validator = described_class.new(
        entry:,
        effective_questions: EffectiveApplicationQuestions.for(contest_instance),
        answers_params: {
          campus_question.id.to_s => '12',
          school_question.id.to_s => '34'
        }
      )
      validator.call
      values = validator.built_answers.index_by { |a| a.application_question.system_key }
      expect(values['campus'].value).to eq(12)
      expect(values['school'].value).to eq(34)
    end

    it 'normalizes blank campus/school values to nil' do
      validator = described_class.new(
        entry:,
        effective_questions: EffectiveApplicationQuestions.for(contest_instance),
        answers_params: {
          campus_question.id.to_s => '',
          school_question.id.to_s => ''
        }
      )
      validator.call
      values = validator.built_answers.index_by { |a| a.application_question.system_key }
      expect(values['campus'].value).to be_nil
      expect(values['school'].value).to be_nil
    end
  end

  describe 'class-level scoped questions' do
    let!(:department_question) { container.application_questions.find_by!(system_key: 'department') }
    let!(:major_question) { container.application_questions.find_by!(system_key: 'major') }
    let(:undergraduate_level) { create(:class_level, name: 'First year') }
    let(:graduate_level) { create(:class_level, name: 'Graduate') }

    before do
      require_question!(department_question)
      require_question!(major_question)
    end

    it 'does not require department for undergraduates' do
      entry.profile.class_level = undergraduate_level

      expect(validate!({ major_question.id.to_s => 'English' })).to be(true)
    end

    it 'does not require major for graduate students' do
      entry.profile.class_level = graduate_level

      expect(validate!(department_question.id.to_s => 'English')).to be(true)
    end

    it 'still requires department for graduate students' do
      entry.profile.class_level = graduate_level

      expect(validate!({})).to be(false)
      expect(entry.errors[:base].join).to include('Department (if graduate)')
    end
  end

  describe 'optional questions' do
    let!(:degree_question) { container.application_questions.find_by!(system_key: 'degree') }

    before { optional_question!(degree_question) }

    it 'allows blank optional answers' do
      expect(validate!({})).to be(true)
    end
  end
end
