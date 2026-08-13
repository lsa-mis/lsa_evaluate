# frozen_string_literal: true

module ApplicationQuestionsHelper
  def question_status_options(include_inherit: false)
    options = ApplicationQuestionRequirement::STATUSES.map { |status| [status.titleize, status] }
    options.unshift([ 'Inherit', 'inherit' ]) if include_inherit
    options
  end

  def inherited_requirement_status(question, requireable)
    case requireable
    when ContestDescription
      requireable.container.application_question_requirements.find_by(application_question: question)&.status
    when ContestInstance
      description = requireable.contest_description
      description.application_question_requirements.find_by(application_question: question)&.status ||
        description.container.application_question_requirements.find_by(application_question: question)&.status
    end
  end

  def render_application_question_field(form_builder_or_nil, question:, name:, value: nil, required: false)
    field_name = name
    case question.field_type
    when 'boolean'
      check_box_tag field_name, '1', ActiveModel::Type::Boolean.new.cast(value),
                    class: 'form-check-input', id: dom_id(question, :answer), required: false
    when 'text'
      text_area_tag field_name, value, class: 'form-control', rows: 3, required: required, id: dom_id(question, :answer)
    when 'date'
      date_field_tag field_name, value, class: 'form-control', required: required, id: dom_id(question, :answer)
    when 'select'
      choices = Array(question.options&.dig('choices') || question.options&.dig(:choices))
      select_tag field_name, options_for_select(choices, value),
                 include_blank: true, class: 'form-select', required: required, id: dom_id(question, :answer)
    when 'select_with_other'
      choices = Array(question.options&.dig('choices') || question.options&.dig(:choices))
      choice_value = value.is_a?(Hash) ? (value['choice'] || value[:choice]) : value
      other_value = value.is_a?(Hash) ? (value['other'] || value[:other]) : nil
      safe_join([
        select_tag("#{field_name}[choice]", options_for_select(choices, choice_value),
                   include_blank: true, class: 'form-select mb-2', required: required, id: dom_id(question, :choice)),
        text_field_tag("#{field_name}[other]", other_value, class: 'form-control',
                       placeholder: 'If Other, please specify', id: dom_id(question, :other))
      ])
    when 'campus'
      select_tag field_name,
                 options_from_collection_for_select(Campus.all, :id, :campus_descr, value),
                 include_blank: true, class: 'form-select', required: required, id: dom_id(question, :answer)
    when 'school'
      select_tag field_name,
                 options_from_collection_for_select(School.all, :id, :name, value),
                 include_blank: true, class: 'form-select', required: required, id: dom_id(question, :answer)
    else
      text_field_tag field_name, value, class: 'form-control', required: required, id: dom_id(question, :answer)
    end
  end
end
