# frozen_string_literal: true

class AddApplicationQuestionsInstructionsEditableContent < ActiveRecord::Migration[8.0]
  BODY = <<~HTML.squish
    <p>
      Application questions collect information from applicants when they submit an entry.
      This page is the collection-level question library: set each question to required,
      optional, or off by default. Contests and contest instances can override those defaults.
    </p>

    <h3>Three kinds of applicant information</h3>
    <ul>
      <li>
        <strong>Profile questions</strong> live on the applicant&rsquo;s profile
        (for example class level and related standing). They persist across contests and are
        not managed on this page. Changing class level on an entry updates the profile and
        can change which contests and questions the applicant sees.
      </li>
      <li>
        <strong>Dynamic system questions</strong> are seeded for every collection
        (pen name, department, major, school, campus, financial aid, acknowledgements, and others).
        You can change labels, help text, and default required/optional/off status here, but you
        cannot delete them. Some system questions also drive special entry-form behavior.
      </li>
      <li>
        <strong>Collection-specific (custom) questions</strong> are added on this page for this
        collection only. You can create, edit, reorder, and delete them, and set their default
        required/optional/off status like system questions.
      </li>
    </ul>

    <h3>Class level and status-based system questions</h3>
    <p>
      A few system questions appear only for certain class levels when an applicant submits:
    </p>
    <ul>
      <li>
        <strong>Department</strong> is shown for graduate class levels.
        Answers use a curated department list (with an &ldquo;Other&rdquo; option).
      </li>
      <li>
        <strong>Major</strong> is shown for undergraduate class levels.
      </li>
      <li>
        <strong>School or college</strong>, <strong>campus</strong>, and similar status fields
        can appear for all class levels when enabled. Graduate applicants are often guided toward
        Rackham for school or college unless another school applies.
      </li>
    </ul>
    <p>
      Questions that do not apply to the applicant&rsquo;s selected class level are hidden on the
      entry form even if they are set to required or optional here.
    </p>
  HTML

  def up
    return if EditableContent.exists?(page: 'application_questions', section: 'instructions')

    record = EditableContent.new(page: 'application_questions', section: 'instructions')
    record.content = BODY
    record.save!
  end

  def down
    EditableContent.where(page: 'application_questions', section: 'instructions').delete_all
  end
end
