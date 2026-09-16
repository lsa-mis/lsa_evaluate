# frozen_string_literal: true

require 'csv'

class AwardsExportService
  def initialize(entries:, title:, contest_instance: nil)
    @entries = entries
    @title = title
    @contest_instance = contest_instance
  end

  def roster_csv
    questions = application_questions

    CSV.generate do |csv|
      csv << [ @title ]
      csv << []
      csv << roster_headers(questions)

      awarded_entries.each do |entry|
        csv << roster_row(entry, questions)
      end
    end
  end

  def disbursement_csv
    CSV.generate do |csv|
      csv << [ @title ]
      csv << []
      csv << disbursement_headers

      entry_awards.each do |entry_award|
        csv << disbursement_row(entry_award)
      end
    end
  end

  private

  def awarded_entries
    @entries.merge(Entry.awarded).includes(
      :category,
      :entry_answers,
      { entry_awards: :award },
      { profile: [ :user, :class_level, :school, :campus ] },
      contest_instance: :contest_description
    )
  end

  def entry_awards
    EntryAward.where(entry_id: @entries.select(:id))
              .includes(
                award: {},
                entry: [
                  :category,
                  { profile: [ :user, :class_level, :school, :campus ] },
                  { contest_instance: :contest_description }
                ]
              )
              .order(:id)
  end

  def application_questions
    return [] unless @contest_instance

    EffectiveApplicationQuestions.for(@contest_instance).map(&:question)
  end

  def roster_headers(questions)
    identity_headers + [
      'Award Status', 'Placement',
      'Primary Award', 'Primary Amount', 'Primary Shortcode',
      'Add-on Awards', 'Add-on Amounts', 'Add-on Shortcodes',
      'Total Amount'
    ] + questions.map(&:label)
  end

  def disbursement_headers
    identity_headers + [
      'Award Status', 'Placement',
      'Prize Name', 'Prize Kind', 'Amount', 'Shortcode'
    ]
  end

  def identity_headers
    [
      'Contest', 'Instance Open', 'Instance Closed',
      'Title', 'Category',
      'First Name', 'Last Name', 'Display Name', 'Email',
      'UMID', 'Uniqname', 'Class Level', 'Campus', 'School',
      'Entry ID'
    ]
  end

  def roster_row(entry, questions)
    primary = entry.primary_entry_award
    add_ons = entry.add_on_entry_awards
    answers_by_question_id = entry.entry_answers.index_by(&:application_question_id)

    identity_cells(entry) + [
      csv_safe_cell(entry.award_status_label),
      csv_safe_cell(entry.placement_label),
      csv_safe_cell(primary&.award&.name),
      format_amount(primary&.amount),
      csv_safe_cell(primary&.shortcode),
      csv_safe_cell(add_ons.map { |entry_award| entry_award.award&.name }.compact.join('; ')),
      csv_safe_cell(add_ons.map { |entry_award| format_amount(entry_award.amount) }.join('; ')),
      csv_safe_cell(add_ons.map(&:shortcode).compact_blank.join('; ')),
      format_amount(entry.total_award_amount)
    ] + questions.map { |question|
      csv_safe_cell(answers_by_question_id[question.id]&.display_value)
    }
  end

  def disbursement_row(entry_award)
    entry = entry_award.entry
    identity_cells(entry) + [
      csv_safe_cell(entry.award_status_label),
      csv_safe_cell(entry.placement_label),
      csv_safe_cell(entry_award.award&.name),
      csv_safe_cell(entry_award.award&.kind_label),
      format_amount(entry_award.amount),
      csv_safe_cell(entry_award.shortcode)
    ]
  end

  def identity_cells(entry)
    profile = entry.profile
    contest_instance = entry.contest_instance
    contest_description = contest_instance.contest_description

    [
      csv_safe_cell(contest_description.name),
      contest_instance.date_open.strftime('%m/%d/%Y'),
      contest_instance.date_closed.strftime('%m/%d/%Y'),
      csv_safe_cell(entry.title),
      csv_safe_cell(entry.category&.kind),
      csv_safe_cell(profile&.legal_first_name.presence || profile&.user&.first_name),
      csv_safe_cell(profile&.legal_last_name.presence || profile&.user&.last_name),
      csv_safe_cell(profile&.display_name),
      csv_safe_cell(profile&.user&.email),
      csv_safe_cell(profile&.umid),
      csv_safe_cell(profile&.user&.uniqname),
      csv_safe_cell(profile&.class_level&.name),
      csv_safe_cell(profile&.campus&.campus_descr),
      csv_safe_cell(profile&.school&.name),
      entry.id
    ]
  end

  def format_amount(amount)
    return '' if amount.blank?

    format('%.2f', amount)
  end

  def csv_safe_cell(value)
    text = value.to_s
    return text if text.empty?

    text.start_with?('=', '+', '-', '@', "\t", "\r") ? "'#{text}" : text
  end
end
