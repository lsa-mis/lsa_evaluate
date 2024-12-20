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
      let(:contest_instance) do
        create(:contest_instance,
              date_open: 2.days.ago,
              date_closed: 1.day.ago)
      end

      context 'when there is no current judging round' do
        it 'returns false' do
          expect(contest_instance.judging_open?).to be false
        end
      end

      context 'with an active judging round' do
        let!(:judging_round) do
          create(:judging_round,
                contest_instance: contest_instance,
                start_date: 1.hour.ago,
                end_date: 1.day.from_now,
                active: true)
        end

        it 'returns true when within judging round dates' do
          expect(contest_instance.judging_open?).to be true
        end

        it 'returns false when before judging round start_date' do
          travel_to(judging_round.start_date - 1.day) do
            expect(contest_instance.judging_open?).to be false
          end
        end

        it 'returns false when after judging round end_date' do
          travel_to(judging_round.end_date + 1.day) do
            expect(contest_instance.judging_open?).to be false
          end
        end
      end

      context 'with an inactive judging round' do
        let!(:judging_round) do
          round = create(:judging_round,
                contest_instance: contest_instance,
                start_date: Time.current,
                end_date: 1.day.from_now)
          round.deactivate!
          round
        end


        it 'returns false even when within judging round dates' do
          expect(contest_instance.judging_open?).to be false
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
end
