# == Schema Information
#
# Table name: judging_rounds
#
#  id                         :bigint           not null, primary key
#  active                     :boolean          default(FALSE), not null
#  completed                  :boolean          default(FALSE), not null
#  end_date                   :datetime
#  min_external_comment_words :integer          default(0), not null
#  min_internal_comment_words :integer          default(0), not null
#  require_external_comments  :boolean          default(FALSE), not null
#  require_internal_comments  :boolean          default(FALSE), not null
#  round_number               :integer          not null
#  start_date                 :datetime
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  contest_instance_id        :bigint           not null
#
# Indexes
#
#  index_judging_rounds_on_contest_instance_id                   (contest_instance_id)
#  index_judging_rounds_on_contest_instance_id_and_round_number  (contest_instance_id,round_number) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (contest_instance_id => contest_instances.id)
#
require 'rails_helper'

RSpec.describe JudgingRound, type: :model do
  describe 'validations' do
    let(:contest_instance) { create(:contest_instance, date_closed: 1.day.from_now) }
    let(:judging_round) { build(:judging_round, contest_instance: contest_instance) }

    context 'first round validation' do
      it 'is invalid if start date is before contest close date' do
        judging_round.round_number = 1
        judging_round.start_date = contest_instance.date_closed - 1.day
        expect(judging_round).not_to be_valid
        expect(judging_round.errors[:start_date]).to include(/must be after contest close date/)
      end

      it 'is valid if start date is after contest close date' do
        judging_round.round_number = 1
        judging_round.start_date = contest_instance.date_closed + 1.hour
        expect(judging_round).to be_valid
      end
    end

    context 'subsequent rounds validation' do
      let!(:first_round) do
        create(:judging_round,
              contest_instance: contest_instance,
              round_number: 1,
              start_date: contest_instance.date_closed + 1.day,
              end_date: contest_instance.date_closed + 2.days)
      end

      it 'is invalid if start date is before previous round end date' do
        second_round = build(:judging_round,
                           contest_instance: contest_instance,
                           round_number: 2,
                           start_date: first_round.end_date - 1.hour)
        expect(second_round).not_to be_valid
        expect(second_round.errors[:start_date]).to include(/must be after the previous round's end date/)
      end

      it 'is valid if start date is after previous round end date' do
        second_round = build(:judging_round,
                           contest_instance: contest_instance,
                           round_number: 2,
                           start_date: first_round.end_date + 1.hour,
                           end_date: first_round.end_date + 2.days)
        expect(second_round).to be_valid
      end
    end
  end
end
