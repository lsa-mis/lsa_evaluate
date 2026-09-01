# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Entry submission application questions' do
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
    EntryAnswersValidator.new(entry:, effective_questions: effective, answers_params:).call
  end

  def built_answer_for(question, answers_params)
    effective = EffectiveApplicationQuestions.for(contest_instance)
    validator = EntryAnswersValidator.new(entry:, effective_questions: effective, answers_params:)
    validator.call
    validator.built_answers.find { |a| a.application_question_id == question.id }
  end

  describe 'agreement-style booleans' do
    ApplicationQuestion::AGREEMENT_SYSTEM_KEYS.each do |system_key|
      context "when #{system_key} is required" do
        let(:question) { container.application_questions.find_by!(system_key:) }

        before { require_question!(question) }

        it 'rejects a missing answer' do
          expect(validate!({})).to be(false)
          expect(entry.errors[:base].join).to include('must be accepted')
        end

        it 'rejects an explicit unchecked value' do
          expect(validate!(question.id.to_s => '0')).to be(false)
          expect(entry.errors[:base].join).to include('must be accepted')
        end

        it 'accepts an explicit checked value' do
          expect(validate!(question.id.to_s => '1')).to be(true)
        end
      end
    end

    context 'when a custom boolean requires acceptance' do
      let(:question) do
        create(
          :application_question,
          container:,
          field_type: 'boolean',
          label: 'I certify this work is my own',
          key: 'certify_original_work',
          options: { 'requires_acceptance' => true }
        )
      end

      before { require_question!(question) }

      it 'rejects when the agreement is not checked' do
        expect(validate!({})).to be(false)
        expect(entry.errors[:base].join).to include('must be accepted')
      end

      it 'accepts when the agreement is checked' do
        expect(validate!(question.id.to_s => '1')).to be(true)
      end
    end
  end

  describe 'yes/no booleans' do
    let(:campus_employee) { container.application_questions.find_by!(system_key: 'campus_employee') }
    let(:receiving_financial_aid) { container.application_questions.find_by!(system_key: 'receiving_financial_aid') }

    before do
      require_question!(campus_employee)
      require_question!(receiving_financial_aid)
    end

    it 'rejects when a required yes/no answer is missing' do
      expect(validate!(campus_employee.id.to_s => '1')).to be(false)
      expect(entry.errors[:base].join).to include("can't be blank")
    end

    it 'accepts explicit Yes and No answers for all required yes/no questions' do
      answers = {
        campus_employee.id.to_s => '1',
        receiving_financial_aid.id.to_s => '0'
      }

      expect(validate!(answers)).to be(true)
      expect(built_answer_for(campus_employee, answers).value).to be(true)
      expect(built_answer_for(receiving_financial_aid, answers).value).to be(false)
    end

    it 'treats a blank string as missing for required yes/no questions' do
      expect(validate!(campus_employee.id.to_s => '')).to be(false)
      expect(entry.errors[:base].join).to include("can't be blank")
    end
  end

  describe 'optional booleans' do
    let(:campus_employee) { container.application_questions.find_by!(system_key: 'campus_employee') }

    before { optional_question!(campus_employee) }

    it 'defaults a missing answer to false and passes validation' do
      expect(validate!({})).to be(true)
      expect(built_answer_for(campus_employee, {}).value).to be(false)
    end
  end

  describe 'mixed required question types' do
    let(:pen_name) { container.application_questions.find_by!(system_key: 'pen_name') }
    let(:campus_employee) { container.application_questions.find_by!(system_key: 'campus_employee') }
    let(:sole_author) { container.application_questions.find_by!(system_key: 'submission_sole_author') }
    let(:referral) { container.application_questions.find_by!(system_key: 'contest_referral_source') }
    let(:grad_date) { container.application_questions.find_by!(system_key: 'grad_date') }
    let(:campus) { create(:campus) }
    let(:school) { create(:school) }
    let(:campus_question) { container.application_questions.find_by!(system_key: 'campus') }
    let(:school_question) { container.application_questions.find_by!(system_key: 'school') }

    before do
      [pen_name, campus_employee, sole_author, referral, grad_date, campus_question, school_question].each do |question|
        require_question!(question)
      end
    end

    def complete_answers
      {
        pen_name.id.to_s => 'A. Poet',
        campus_employee.id.to_s => '0',
        sole_author.id.to_s => '1',
        referral.id.to_s => { 'choice' => 'Faculty' },
        grad_date.id.to_s => '2027-05-01',
        campus_question.id.to_s => campus.id.to_s,
        school_question.id.to_s => school.id.to_s
      }
    end

    it 'accepts a fully answered submission across field types' do
      expect(validate!(complete_answers)).to be(true)
    end

    it 'rejects when any single required answer is missing' do
      answers = complete_answers.except(campus_employee.id.to_s)

      expect(validate!(answers)).to be(false)
      expect(entry.errors[:base].join).to include("can't be blank")
    end

    it 'rejects when a required agreement is unchecked in an otherwise complete submission' do
      answers = complete_answers.merge(sole_author.id.to_s => '0')

      expect(validate!(answers)).to be(false)
      expect(entry.errors[:base].join).to include('must be accepted')
    end
  end

  describe 'required select, campus, school, and text fields' do
    let(:referral) { container.application_questions.find_by!(system_key: 'contest_referral_source') }
    let(:financial_aid_description) { container.application_questions.find_by!(system_key: 'financial_aid_description') }
    let(:campus_question) { container.application_questions.find_by!(system_key: 'campus') }
    let(:school_question) { container.application_questions.find_by!(system_key: 'school') }

    before do
      require_question!(referral)
      require_question!(financial_aid_description)
      require_question!(campus_question)
      require_question!(school_question)
    end

    it 'rejects blank required text and select answers' do
      expect(validate!({})).to be(false)
      expect(entry.errors[:base].join).to include("can't be blank")
    end

    it 'accepts present answers for text, select, campus, and school' do
      campus = create(:campus)
      school = create(:school)

      answers = {
        referral.id.to_s => { 'choice' => 'Website' },
        financial_aid_description.id.to_s => 'Pell grant',
        campus_question.id.to_s => campus.id.to_s,
        school_question.id.to_s => school.id.to_s
      }

      expect(validate!(answers)).to be(true)
    end
  end

  describe 'class-level scoped requirements during submission' do
    let(:undergraduate_level) { create(:class_level, name: 'First year') }
    let(:graduate_level) { create(:class_level, name: 'Graduate') }
    let(:department) { container.application_questions.find_by!(system_key: 'department') }
    let(:major) { container.application_questions.find_by!(system_key: 'major') }

    before do
      require_question!(department)
      require_question!(major)
    end

    it 'requires major but not department for undergraduates' do
      entry.profile.class_level = undergraduate_level

      expect(validate!({})).to be(false)
      expect(entry.errors[:base].join).to include('Major (if undergraduate)')
      expect(entry.errors[:base].join).not_to include('Department (if graduate)')
    end

    it 'requires department but not major for graduate students' do
      entry.profile.class_level = graduate_level

      expect(validate!({})).to be(false)
      expect(entry.errors[:base].join).to include('Department (if graduate)')
      expect(entry.errors[:base].join).not_to include('Major (if undergraduate)')
    end
  end
end
