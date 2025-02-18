# == Schema Information
#
# Table name: contest_instances
#
#  id                                   :bigint           not null, primary key
#  active                               :boolean          default(FALSE), not null
#  archived                             :boolean          default(FALSE), not null
#  course_requirement_description       :text(65535)
#  created_by                           :string(255)
#  date_closed                          :datetime         not null
#  date_open                            :datetime         not null
#  has_course_requirement               :boolean          default(FALSE), not null
#  maximum_number_entries_per_applicant :integer          default(1), not null
#  notes                                :text(65535)
#  recletter_required                   :boolean          default(FALSE), not null
#  require_campus_employment_info       :boolean          default(FALSE), not null
#  require_finaid_info                  :boolean          default(FALSE), not null
#  require_pen_name                     :boolean          default(FALSE), not null
#  transcript_required                  :boolean          default(FALSE), not null
#  created_at                           :datetime         not null
#  updated_at                           :datetime         not null
#  contest_description_id               :bigint           not null
#
# Indexes
#
#  contest_description_id_idx                         (contest_description_id)
#  id_unq_idx                                         (id) UNIQUE
#  index_contest_instances_on_contest_description_id  (contest_description_id)
#
# Foreign Keys
#
#  fk_rails_...  (contest_description_id => contest_descriptions.id)
#
require 'rails_helper'

RSpec.describe ContestInstance, type: :model do
  describe 'judge assignment methods' do
    let(:contest_instance) { create(:contest_instance) }
    let(:judge) { create(:user, :with_judge_role) }
    let(:regular_user) { create(:user) }
    let(:judging_round) { create(:judging_round, contest_instance: contest_instance) }

    describe '#judge_assigned?' do
      it 'returns false for non-judge users' do
        expect(contest_instance.judge_assigned?(regular_user)).to be false
      end

      it 'returns false for unassigned judges' do
        expect(contest_instance.judge_assigned?(judge)).to be false
      end

      it 'returns true for assigned judges' do
        create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)
        expect(contest_instance.judge_assigned?(judge)).to be true
      end

      it 'returns false for inactive assignments' do
        create(:judging_assignment, user: judge, contest_instance: contest_instance, active: false)
        expect(contest_instance.judge_assigned?(judge)).to be false
      end
    end

    describe '#judge_assigned_to_round?' do
      let!(:judging_assignment) do
        create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)
      end

      it 'returns false when judge is not assigned to round' do
        expect(contest_instance.judge_assigned_to_round?(judge, judging_round)).to be false
      end

      it 'returns true when judge is assigned to round' do
        create(:round_judge_assignment, user: judge, judging_round: judging_round, active: true)
        expect(contest_instance.judge_assigned_to_round?(judge, judging_round)).to be true
      end

      it 'returns false when round assignment is inactive' do
        create(:round_judge_assignment, user: judge, judging_round: judging_round, active: false)
        expect(contest_instance.judge_assigned_to_round?(judge, judging_round)).to be false
      end

      it 'returns false when contest assignment is inactive' do
        judging_assignment.update(active: false)
        create(:round_judge_assignment, user: judge, judging_round: judging_round, active: true)
        expect(contest_instance.judge_assigned_to_round?(judge, judging_round)).to be false
      end
    end
  end

  describe 'judging status methods' do
    let(:contest_instance) { create(:contest_instance) }

    describe '#judging_open?' do
      let(:contest_instance) { create(:contest_instance) }
      let(:judge) { create(:user, :with_judge_role) }
      let!(:judging_round) do
        create(:judging_round,
          contest_instance: contest_instance,
          active: true,
          start_date: 1.day.ago,
          end_date: 1.day.from_now
        )
      end

      context 'when no user is specified' do
        it 'returns true if there is an active round within date range' do
          expect(contest_instance.judging_open?).to be true
        end

        it 'returns false if there is no active round' do
          judging_round.update!(active: false)
          expect(contest_instance.judging_open?).to be false
        end

        it 'returns false if active round is outside date range' do
          judging_round.update!(start_date: 1.day.from_now, end_date: 2.days.from_now)
          expect(contest_instance.judging_open?).to be false
        end
      end

      context 'when user is specified' do
        before do
          create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)
        end

        it 'returns true if judge is assigned to the active round' do
          create(:round_judge_assignment, user: judge, judging_round: judging_round, active: true)
          expect(contest_instance.judging_open?(judge)).to be true
        end

        it 'returns false if judge is not assigned to the active round' do
          expect(contest_instance.judging_open?(judge)).to be false
        end

        it 'returns false if judge assignment is inactive' do
          create(:round_judge_assignment, user: judge, judging_round: judging_round, active: false)
          expect(contest_instance.judging_open?(judge)).to be false
        end

        it 'returns false if contest assignment is inactive' do
          create(:round_judge_assignment, user: judge, judging_round: judging_round, active: true)
          contest_instance.judging_assignments.last.update!(active: false)
          expect(contest_instance.judging_open?(judge)).to be false
        end
      end
    end

    describe '#judge_evaluations_complete?' do
      context 'when there are no judging rounds' do
        it 'returns false' do
          expect(contest_instance.judge_evaluations_complete?).to be false
        end
      end

      context 'when there are judging rounds' do
        let!(:round1) {
          create(:judging_round,
                contest_instance: contest_instance,
                round_number: 1,
                start_date: 1.day.from_now,
                end_date: 2.days.from_now,
                completed: false)
        }

        it 'returns false when the last round is not completed' do
          expect(contest_instance.judge_evaluations_complete?).to be false
        end

        it 'returns true when the last round is completed' do
          round1.update(completed: true)
          expect(contest_instance.judge_evaluations_complete?).to be true
        end

        context 'with multiple rounds' do
          let!(:round2) {
            create(:judging_round,
                  contest_instance: contest_instance,
                  round_number: 2,
                  start_date: 3.days.from_now,
                  end_date: 4.days.from_now,
                  completed: false)
          }

          it 'returns false when the last round is not completed, even if earlier rounds are' do
            round1.update(completed: true)
            expect(contest_instance.judge_evaluations_complete?).to be false
          end

          it 'returns true when the last round is completed, regardless of earlier rounds' do
            round1.update!(completed: false, active: false)
            expect(round2.update!(completed: true)).to be true

            # Force reload of both the round and the association
            round2.reload
            contest_instance.reload
            expect(contest_instance.judge_evaluations_complete?).to be true
          end
        end
      end
    end
  end

  describe 'scopes' do
    describe '.active_and_open' do
      let!(:open_instance) do
        create(:contest_instance,
               active: true,
               archived: false,
               date_open: 1.day.ago,
               date_closed: 1.day.from_now)
      end

      let!(:closed_instance) do
        create(:contest_instance,
               active: true,
               archived: false,
               date_open: 2.days.ago,
               date_closed: 1.day.ago)
      end

      let!(:archived_instance) do
        create(:contest_instance,
               active: true,
               archived: true,
               date_open: 1.day.ago,
               date_closed: 1.day.from_now)
      end

      it 'includes only active, non-archived, and currently open instances' do
        active_instances = ContestInstance.active_and_open

        expect(active_instances).to include(open_instance)
        expect(active_instances).not_to include(closed_instance)
        expect(active_instances).not_to include(archived_instance)
      end
    end

    describe '.available_for_profile' do
      let(:profile) { create(:profile) }
      let(:contest_instance) { create(:contest_instance, maximum_number_entries_per_applicant: 2) }

      it 'excludes contests where profile has reached maximum entries' do
        create_list(:entry, 2, profile: profile, contest_instance: contest_instance)

        available_instances = ContestInstance.available_for_profile(profile)
        expect(available_instances).not_to include(contest_instance)
      end

      it 'includes contests where profile has not reached maximum entries' do
        create(:entry, profile: profile, contest_instance: contest_instance)

        available_instances = ContestInstance.available_for_profile(profile)
        expect(available_instances).to include(contest_instance)
      end
    end
  end
end
