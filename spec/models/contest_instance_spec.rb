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
#  judge_evaluations_complete           :boolean          default(FALSE), not null
#  judging_open                         :boolean          default(FALSE), not null
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
end 
