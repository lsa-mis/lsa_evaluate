# frozen_string_literal: true

class AddSessionTimeoutEditableContent < ActiveRecord::Migration[8.0]
  ADMIN_BODY = <<~HTML.squish
    <p><strong>Judge session timeout:</strong> Judges are signed out after 2 hours of inactivity in LSA Evaluate.</p>
    <ul>
      <li>Rankings save automatically when judges reorder entries or leave a comment field.</li>
      <li>After about 1 hour 50 minutes of inactivity, judges see a prompt to stay signed in.</li>
      <li>Reading entries for a long time without interacting may still allow the session to expire.</li>
      <li>UMich single sign-on may also sign judges out independently of this timeout.</li>
    </ul>
  HTML

  JUDGE_BODY = <<~HTML.squish
    <p>Your session expires after <strong>2 hours of inactivity</strong>. Rankings save when you reorder entries or move out of a comment field.</p>
    <p>After about 1 hour 50 minutes without activity, you will see a prompt to stay signed in.</p>
  HTML

  def up
    seed_editable_content('judging_assignments', 'session_timeout_guidance', ADMIN_BODY)
    seed_editable_content('judge_dashboard', 'session_timeout_guidance', JUDGE_BODY)
  end

  def down
    EditableContent.where(
      page: %w[judging_assignments judge_dashboard],
      section: 'session_timeout_guidance'
    ).delete_all
  end

  private

  def seed_editable_content(page, section, body)
    return if EditableContent.exists?(page: page, section: section)

    record = EditableContent.new(page: page, section: section)
    record.content = body
    record.save!
  end
end
