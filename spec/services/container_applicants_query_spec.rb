# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContainerApplicantsQuery do
  let(:container) { create(:container) }
  let(:other_container) { create(:container) }
  let(:ann_arbor) { create(:campus, campus_descr: 'Ann Arbor') }
  let(:dearborn) { create(:campus, campus_descr: 'Dearborn') }
  let(:poetry) { create(:contest_description, :active, container: container, name: 'Poetry') }
  let(:fiction) { create(:contest_description, :active, container: container, name: 'Fiction') }
  let(:active_poetry) { create(:contest_instance, contest_description: poetry, active: true) }
  let(:active_fiction) { create(:contest_instance, contest_description: fiction, active: true) }

  def create_applicant!(legal_last_name:, legal_first_name:, campus: nil, preferred_last_name: nil, preferred_first_name: nil)
    user = create(:user)
    create(
      :profile,
      user: user,
      legal_last_name: legal_last_name,
      legal_first_name: legal_first_name,
      preferred_last_name: preferred_last_name,
      preferred_first_name: preferred_first_name,
      campus: campus
    )
  end

  def query_for(**filters)
    described_class.new(container: container, **filters)
  end

  describe '#profiles and #rows_for' do
    it 'returns one row per person with submission counts and contests' do
      ada = create_applicant!(legal_last_name: 'Lovelace', legal_first_name: 'Ada', campus: ann_arbor)
      moe = create_applicant!(legal_last_name: 'Manager', legal_first_name: 'Moe', campus: dearborn)
      create(:entry, contest_instance: active_poetry, profile: ada, title: 'Poem One')
      create(:entry, contest_instance: active_fiction, profile: ada, title: 'Story One')
      create(:entry, contest_instance: active_poetry, profile: moe, title: 'Moe Poem')

      other_description = create(:contest_description, :active, container: other_container)
      other_instance = create(:contest_instance, contest_description: other_description, active: true)
      create(:entry, contest_instance: other_instance, profile: create_applicant!(legal_last_name: 'Outsider', legal_first_name: 'Other'))

      create(:entry, contest_instance: active_poetry, profile: create_applicant!(legal_last_name: 'Gone', legal_first_name: 'Deleted'), deleted: true)

      results = query_for.rows_for(query_for.profiles)
      expect(results.map { |row| row.profile.id }).to eq([ada.id, moe.id])
      ada_row = results.first
      expect(ada_row.submission_count).to eq(2)
      expect(ada_row.contest_names).to eq(%w[Fiction Poetry])
      expect(ada_row.campus_name).to eq('Ann Arbor')
      expect(ada_row.name).to include('Ada').or include(ada.display_name)
    end

    it 'filters by name across legal and preferred names' do
      match = create_applicant!(
        legal_last_name: 'Smith',
        legal_first_name: 'Pat',
        preferred_last_name: 'Zebra',
        preferred_first_name: 'Skip',
        campus: ann_arbor
      )
      create(:entry, contest_instance: active_poetry, profile: match)
      other = create_applicant!(legal_last_name: 'Jones', legal_first_name: 'Ann', campus: ann_arbor)
      create(:entry, contest_instance: active_poetry, profile: other)

      expect(query_for(name: 'Zebra').profiles).to contain_exactly(match)
      expect(query_for(name: 'Pat Smith').profiles).to contain_exactly(match)
    end

    it 'filters by profile campus and by campus answers when profile campus is blank' do
      from_profile = create_applicant!(legal_last_name: 'Profile', legal_first_name: 'Campus', campus: ann_arbor)
      create(:entry, contest_instance: active_poetry, profile: from_profile)

      from_answer = create_applicant!(legal_last_name: 'Answer', legal_first_name: 'Campus', campus: nil)
      entry = create(:entry, contest_instance: active_poetry, profile: from_answer)
      campus_question = container.application_questions.find_by!(system_key: 'campus')
      EntryAnswer.create!(entry: entry, application_question: campus_question, value: ann_arbor.id)

      dearborn_person = create_applicant!(legal_last_name: 'Dearborn', legal_first_name: 'Person', campus: dearborn)
      create(:entry, contest_instance: active_poetry, profile: dearborn_person)

      results = query_for(campus_id: ann_arbor.id).profiles
      expect(results).to contain_exactly(from_profile, from_answer)
    end

    it 'defaults to active instances and can include a historical year' do
      current = create_applicant!(legal_last_name: 'Now', legal_first_name: 'Active', campus: ann_arbor)
      create(:entry, contest_instance: active_poetry, profile: current)

      past_instance = create(
        :contest_instance,
        contest_description: poetry,
        active: false,
        date_open: Time.zone.local(2024, 2, 1),
        date_closed: Time.zone.local(2024, 3, 1)
      )
      historical = create_applicant!(legal_last_name: 'Then', legal_first_name: 'Past', campus: dearborn)
      create(:entry, contest_instance: past_instance, profile: historical)

      expect(query_for.profiles).to contain_exactly(current)
      expect(query_for(year: '2024').profiles).to contain_exactly(historical)
      expect(query_for(year: 'all').profiles).to contain_exactly(current, historical)
    end

    it 'marks finalists from the last judging round' do
      finalist = create_applicant!(legal_last_name: 'Winner', legal_first_name: 'Pat', campus: ann_arbor)
      advanced = create_applicant!(legal_last_name: 'Advance', legal_first_name: 'Lee', campus: dearborn)
      finalist_entry = create(:entry, contest_instance: active_poetry, profile: finalist)
      advanced_entry = create(:entry, contest_instance: active_poetry, profile: advanced)

      round_one = create(
        :judging_round,
        contest_instance: active_poetry,
        round_number: 1,
        start_date: active_poetry.date_closed + 1.hour,
        end_date: active_poetry.date_closed + 2.days
      )
      round_one.update_columns(active: false, completed: true)
      round_two = create(
        :judging_round,
        contest_instance: active_poetry,
        round_number: 2,
        active: true,
        start_date: round_one.end_date + 1.hour,
        end_date: round_one.end_date + 2.days
      )
      create(:entry_ranking, :selected, :with_assigned_judge, entry: finalist_entry, judging_round: round_two)
      create(:entry_ranking, :selected, :with_assigned_judge, entry: advanced_entry, judging_round: round_one)

      rows = query_for.rows_for(query_for.profiles)
      expect(rows.find { |row| row.profile == finalist }.finalist_contest_names).to eq(['Poetry'])
      expect(rows.find { |row| row.profile == advanced }.finalist_contest_names).to eq([])
    end
  end

  describe '#summary' do
    it 'counts unique people and submissions, including unknown campus' do
      ada = create_applicant!(legal_last_name: 'Lovelace', legal_first_name: 'Ada', campus: ann_arbor)
      create(:entry, contest_instance: active_poetry, profile: ada)
      create(:entry, contest_instance: active_fiction, profile: ada)
      unknown = create_applicant!(legal_last_name: 'Mystery', legal_first_name: 'Person', campus: nil)
      create(:entry, contest_instance: active_poetry, profile: unknown)

      summary = query_for.summary
      expect(summary.unique_submitters).to eq(2)
      expect(summary.total_submissions).to eq(3)
      ann_arbor_row = summary.by_campus.find { |row| row.campus_descr == 'Ann Arbor' }
      unknown_row = summary.by_campus.find { |row| row.campus_descr == 'Unknown' }
      expect(ann_arbor_row.entry_count).to eq(2)
      expect(ann_arbor_row.unique_people).to eq(1)
      expect(unknown_row.entry_count).to eq(1)
      expect(unknown_row.unique_people).to eq(1)
    end
  end

  describe '#available_years' do
    it 'lists years from submissions in the collection' do
      create(:entry, contest_instance: active_poetry, profile: create_applicant!(legal_last_name: 'Now', legal_first_name: 'A'))
      past_instance = create(
        :contest_instance,
        contest_description: poetry,
        active: false,
        date_open: Time.zone.local(2024, 2, 1),
        date_closed: Time.zone.local(2024, 3, 1)
      )
      create(:entry, contest_instance: past_instance, profile: create_applicant!(legal_last_name: 'Then', legal_first_name: 'B'))

      expect(query_for.available_years).to include(2024, Time.zone.now.year)
    end
  end
end
