# frozen_string_literal: true

class ProfileCampusBackfill
  def self.call
    new.call
  end

  def initialize
    @updated = 0
  end

  def call
    Profile.where(campus_id: nil).find_each do |profile|
      campus_id = latest_campus_id_for(profile.id)
      next if campus_id.blank?

      profile.update_columns(campus_id: campus_id, updated_at: Time.current)
      @updated += 1
    end

    @updated
  end

  private

  def latest_campus_id_for(profile_id)
    answer = EntryAnswer
      .joins(:entry, :application_question)
      .where(entries: { profile_id: profile_id, deleted: false })
      .where(application_questions: { field_type: 'campus' })
      .order('entries.created_at DESC', 'entry_answers.id DESC')
      .first

    answer&.campus_id_value
  end
end
