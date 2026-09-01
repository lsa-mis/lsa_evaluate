# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationQuestionsHelper, type: :helper do
  let(:container) { create(:container) }
  let(:question) { container.application_questions.find_by!(system_key: 'degree') }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }

  describe '#question_status_options' do
    it 'includes inherit when requested' do
      options = helper.question_status_options(include_inherit: true)
      expect(options).to include([ 'Inherit', 'inherit' ])
      expect(options.map(&:last)).to include('required', 'optional', 'off')
    end

    it 'omits inherit by default' do
      options = helper.question_status_options
      expect(options.map(&:last)).not_to include('inherit')
    end
  end

  describe '#inherited_requirement_status' do
    it 'returns the container requirement for a contest description' do
      ApplicationQuestionRequirement.create!(
        application_question: question,
        requireable: container,
        status: 'required'
      )

      expect(helper.inherited_requirement_status(question, contest_description)).to eq('required')
    end

    it 'prefers contest description requirements over container for instances' do
      ApplicationQuestionRequirement.create!(
        application_question: question,
        requireable: container,
        status: 'required'
      )
      ApplicationQuestionRequirement.create!(
        application_question: question,
        requireable: contest_description,
        status: 'optional'
      )

      expect(helper.inherited_requirement_status(question, contest_instance)).to eq('optional')
    end

    it 'falls back to the container requirement when description has none' do
      ApplicationQuestionRequirement.create!(
        application_question: question,
        requireable: container,
        status: 'off'
      )

      expect(helper.inherited_requirement_status(question, contest_instance)).to eq('off')
    end
  end

  describe '#render_application_question_field' do
    it 'renders select_with_other choice and other inputs from a hash value' do
      question = container.application_questions.find_by!(system_key: 'contest_referral_source')
      html = helper.render_application_question_field(
        nil,
        question: question,
        name: 'answers[contest_referral_source]',
        value: { 'choice' => 'Other', 'other' => 'Bus ad' },
        required: true
      ).to_s

      expect(html).to include('name="answers[contest_referral_source][choice]"')
      expect(html).to include('selected="selected"')
      expect(html).to include('value="Other"')
      expect(html).to include('name="answers[contest_referral_source][other]"')
      expect(html).to include('value="Bus ad"')
    end

    it 'casts boolean answers for checkbox checked state' do
      question = container.application_questions.find_by!(system_key: 'accepted_financial_aid_notice')
      checked = helper.render_application_question_field(
        nil,
        question: question,
        name: 'answers[accepted_financial_aid_notice]',
        value: '1'
      ).to_s
      unchecked = helper.render_application_question_field(
        nil,
        question: question,
        name: 'answers[accepted_financial_aid_notice]',
        value: '0'
      ).to_s

      expect(checked).to include('checked="checked"')
      expect(unchecked).not_to include('checked="checked"')
    end

    it 'renders yes/no radio buttons for non-agreement booleans' do
      question = container.application_questions.find_by!(system_key: 'campus_employee')
      html = helper.render_application_question_field(
        nil,
        question: question,
        name: 'answers[campus_employee]',
        value: nil,
        required: true
      ).to_s

      expect(html).to include('type="radio"')
      expect(html).to include('value="1"')
      expect(html).to include('value="0"')
      expect(html).to include('>Yes<')
      expect(html).to include('>No<')
      expect(html).not_to include('checked="checked"')
    end

    it 'selects the correct yes/no radio when a value is present' do
      question = container.application_questions.find_by!(system_key: 'campus_employee')
      yes_html = helper.render_application_question_field(
        nil,
        question: question,
        name: 'answers[campus_employee]',
        value: true
      ).to_s
      no_html = helper.render_application_question_field(
        nil,
        question: question,
        name: 'answers[campus_employee]',
        value: false
      ).to_s

      expect(yes_html).to match(/value="1"[^>]*checked="checked"|checked="checked"[^>]*value="1"/)
      expect(no_html).to match(/value="0"[^>]*checked="checked"|checked="checked"[^>]*value="0"/)
    end

    it 'renders agreement checkboxes for custom booleans with requires_acceptance' do
      question = create(
        :application_question,
        container:,
        field_type: 'boolean',
        label: 'I certify this work',
        key: 'certify_work',
        options: { 'requires_acceptance' => true }
      )
      html = helper.render_application_question_field(
        nil,
        question: question,
        name: 'answers[certify_work]',
        value: nil
      ).to_s

      expect(html).to include('type="checkbox"')
      expect(html).not_to include('type="radio"')
    end
  end
end
