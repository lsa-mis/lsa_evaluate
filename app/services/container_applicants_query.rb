# frozen_string_literal: true

class ContainerApplicantsQuery
  YEAR_ACTIVE = 'active'
  YEAR_ALL = 'all'
  CAMPUS_UNKNOWN = 'unknown'

  Applicant = Struct.new(
    :profile,
    :name,
    :campus_name,
    :years,
    :submission_count,
    :contest_names,
    :finalist_contest_names,
    :email,
    :uniqname,
    :umid,
    :legal_first_name,
    :legal_last_name,
    keyword_init: true
  )

  Summary = Struct.new(
    :unique_submitters,
    :total_submissions,
    :by_campus,
    keyword_init: true
  )

  CampusCount = Struct.new(
    :campus_descr,
    :entry_count,
    :unique_people,
    keyword_init: true
  )

  def initialize(container:, name: nil, campus_id: nil, year: nil)
    @container = container
    @name = name.to_s.strip.presence
    @campus_id = campus_id.presence
    @year = year.presence || YEAR_ACTIVE
  end

  def profiles
    scope = base_profiles
    scope = apply_name_filter(scope)
    scope = apply_campus_filter(scope)
    scope.order('profiles.legal_last_name', 'profiles.legal_first_name', 'profiles.id')
  end

  def rows_for(profile_records)
    profile_list = Array(profile_records)
    return [] if profile_list.empty?

    entries = filtered_entries
      .where(profile_id: profile_list.map(&:id))
      .includes(:entry_rankings, contest_instance: [ :contest_description, :judging_rounds ])
    entries_by_profile = entries.group_by(&:profile_id)
    campus_names = campus_names_for(profile_list)

    profile_list.map do |profile|
      profile_entries = entries_by_profile[profile.id] || []
      contest_names = profile_entries.map { |entry| entry.contest_instance.contest_description.name }.uniq.sort
      years = profile_entries.map { |entry| entry.contest_instance.date_open.in_time_zone.year }.uniq.sort.reverse
      finalist_names = profile_entries.select(&:finalist?).map { |entry|
        entry.contest_instance.contest_description.name
      }.uniq.sort

      Applicant.new(
        profile: profile,
        name: profile.display_name,
        campus_name: campus_names[profile.id],
        years: years,
        submission_count: profile_entries.size,
        contest_names: contest_names,
        finalist_contest_names: finalist_names,
        email: profile.user.email,
        uniqname: profile.user.uniqname,
        umid: profile.umid,
        legal_first_name: profile.legal_first_name,
        legal_last_name: profile.legal_last_name
      )
    end
  end

  def summary
    pairs = filtered_entries.joins(:profile).pluck('entries.profile_id', 'profiles.campus_id')
    unique_submitters = pairs.map(&:first).uniq.size
    total_submissions = pairs.size
    campus_ids_by_profile = latest_campus_ids_for(pairs.select { |_profile_id, campus_id| campus_id.nil? }.map(&:first).uniq)

    grouped = Hash.new { |hash, key| hash[key] = { entries: 0, people: [] } }
    pairs.each do |profile_id, campus_id|
      resolved_id = campus_id || campus_ids_by_profile[profile_id]
      grouped[resolved_id][:entries] += 1
      grouped[resolved_id][:people] << profile_id
    end

    campus_names = Campus.where(id: grouped.keys.compact).pluck(:id, :campus_descr).to_h
    by_campus = grouped.map { |campus_id, counts|
      CampusCount.new(
        campus_descr: campus_names[campus_id] || 'Unknown',
        entry_count: counts[:entries],
        unique_people: counts[:people].uniq.size
      )
    }.sort_by(&:campus_descr)

    Summary.new(
      unique_submitters: unique_submitters,
      total_submissions: total_submissions,
      by_campus: by_campus
    )
  end

  def available_years
    Entry.joins(contest_instance: { contest_description: :container })
         .where(containers: { id: @container.id }, deleted: false)
         .pluck('contest_instances.date_open')
         .map { |opened_at| opened_at.in_time_zone.year }
         .uniq
         .sort
         .reverse
  end

  def year_filter
    @year
  end

  private

  def base_profiles
    Profile.joins(:user)
           .where(id: filtered_entries.select('entries.profile_id'))
  end

  def filtered_entries
    entries = Entry.joins(contest_instance: { contest_description: :container })
                   .where(containers: { id: @container.id }, deleted: false)
    apply_year_filter(entries)
  end

  def apply_year_filter(entries)
    case @year
    when YEAR_ALL
      entries
    when YEAR_ACTIVE, nil, ''
      entries.where(contest_instances: { active: true })
    else
      year = @year.to_i
      range = Time.zone.local(year).beginning_of_year..Time.zone.local(year).end_of_year
      entries.where(contest_instances: { date_open: range })
    end
  end

  def apply_name_filter(scope)
    return scope if @name.blank?

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@name)}%"
    scope.where(
      'profiles.legal_first_name LIKE :q OR profiles.legal_last_name LIKE :q OR ' \
      'profiles.preferred_first_name LIKE :q OR profiles.preferred_last_name LIKE :q OR ' \
      "CONCAT(profiles.legal_first_name, ' ', profiles.legal_last_name) LIKE :q OR " \
      "CONCAT(profiles.preferred_first_name, ' ', profiles.preferred_last_name) LIKE :q",
      q: pattern
    )
  end

  def apply_campus_filter(scope)
    return scope if @campus_id.blank?

    if @campus_id == CAMPUS_UNKNOWN
      nil_ids = scope.where(campus_id: nil).pluck(:id)
      matched_unknown = nil_ids - latest_campus_ids_for(nil_ids).keys
      return scope.where(id: matched_unknown)
    end

    requested_id = @campus_id.to_i
    ids_from_profile = scope.where(campus_id: requested_id).pluck(:id)
    nil_ids = scope.where(campus_id: nil).pluck(:id)
    ids_from_answers = latest_campus_ids_for(nil_ids).select { |_profile_id, campus_id| campus_id == requested_id }.keys
    scope.where(id: ids_from_profile + ids_from_answers)
  end

  def campus_names_for(profiles)
    names = {}
    missing_ids = []

    profiles.each do |profile|
      if profile.campus&.campus_descr.present?
        names[profile.id] = profile.campus.campus_descr
      else
        missing_ids << profile.id
      end
    end

    campus_ids = latest_campus_ids_for(missing_ids)
    campus_lookup = Campus.where(id: campus_ids.values).pluck(:id, :campus_descr).to_h
    missing_ids.each do |profile_id|
      names[profile_id] = campus_lookup[campus_ids[profile_id]] || 'Unknown'
    end

    names
  end

  def latest_campus_ids_for(profile_ids)
    ids = Array(profile_ids).uniq
    return {} if ids.empty?

    rows = EntryAnswer
      .joins(:entry, :application_question)
      .where(entries: { profile_id: ids, deleted: false })
      .where(application_questions: { field_type: 'campus' })
      .order('entries.created_at DESC', 'entry_answers.id DESC')
      .pluck('entries.profile_id', 'entry_answers.value')

    rows.each_with_object({}) do |(profile_id, value), memo|
      next if memo.key?(profile_id)

      campus_id = extract_campus_id(value)
      memo[profile_id] = campus_id if campus_id
    end
  end

  def extract_campus_id(value)
    raw = value.is_a?(Hash) ? (value['value'] || value[:value]) : value
    id = raw.to_i
    id if id.positive?
  end
end
