# == Schema Information
#
# Table name: judging_rounds
#
#  id                         :bigint           not null, primary key
#  active                     :boolean          default(FALSE), not null
#  completed                  :boolean          default(FALSE), not null
#  emails_sent_count          :integer          default(0), not null
#  end_date                   :datetime
#  min_external_comment_words :integer          default(0), not null
#  min_internal_comment_words :integer          default(0), not null
#  require_external_comments  :boolean          default(FALSE), not null
#  require_internal_comments  :boolean          default(FALSE), not null
#  required_entries_count     :integer          default(0), not null
#  round_number               :integer          not null
#  special_instructions       :text(65535)
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

  describe 'automatic activation' do
    let(:contest_instance) { create(:contest_instance, date_closed: 1.day.from_now) }

    context 'when creating the first round' do
      it 'automatically sets active to true' do
        first_round = create(:judging_round,
                           contest_instance: contest_instance,
                           round_number: 1,
                           start_date: contest_instance.date_closed + 1.day,
                           end_date: contest_instance.date_closed + 2.days)
        expect(first_round.reload.active).to be true
      end
    end

    context 'when creating subsequent rounds' do
      let!(:first_round) do
        create(:judging_round,
              contest_instance: contest_instance,
              round_number: 1,
              start_date: contest_instance.date_closed + 1.day,
              end_date: contest_instance.date_closed + 2.days)
      end

      it 'sets active to false by default' do
        second_round = create(:judging_round,
                            contest_instance: contest_instance,
                            round_number: 2,
                            start_date: first_round.end_date + 1.hour,
                            end_date: first_round.end_date + 2.days)
        expect(second_round.reload.active).to be false
      end

      it 'maintains only one active round when manually activating' do
        second_round = create(:judging_round,
                            contest_instance: contest_instance,
                            round_number: 2,
                            start_date: first_round.end_date + 1.hour,
                            end_date: first_round.end_date + 2.days)

        second_round.activate!

        expect(first_round.reload.active).to be true
        expect(second_round.reload.active).to be false
      end

      it 'maintains only one active round when manually completing' do
        second_round = create(:judging_round,
                            contest_instance: contest_instance,
                            round_number: 2,
                            start_date: first_round.end_date + 1.hour,
                            end_date: first_round.end_date + 2.days)
        first_round.complete!
        second_round.activate!

        expect(first_round.reload.active).to be false
        expect(second_round.reload.active).to be true
      end
    end
  end

  describe 'instructions' do
    let(:contest_instance) { create(:contest_instance) }

    it 'can be saved with instructions' do
      judging_round = build(:judging_round,
        contest_instance: contest_instance,
        special_instructions: "Please review entries carefully\nPay attention to formatting"
      )
      expect(judging_round).to be_valid
      expect(judging_round.save).to be true
    end

    it 'can be saved without instructions' do
      judging_round = build(:judging_round,
        contest_instance: contest_instance,
        special_instructions: nil
      )
      expect(judging_round).to be_valid
      expect(judging_round.save).to be true
    end

    it 'preserves line breaks in instructions' do
      instructions = "Line 1\nLine 2\nLine 3"
      judging_round = create(:judging_round,
        contest_instance: contest_instance,
        special_instructions: instructions
      )
      expect(judging_round.reload.special_instructions).to eq(instructions)
    end
  end

  describe '#complete!' do
    let(:contest_instance) { create(:contest_instance, date_open: 1.day.ago, date_closed: 1.day.from_now) }

    context 'with multiple rounds' do
      let!(:first_round) do
        create(:judging_round,
              contest_instance: contest_instance,
              round_number: 1,
              start_date: contest_instance.date_closed + 1.day,
              end_date: contest_instance.date_closed + 2.days)
      end

      let!(:second_round) do
        create(:judging_round,
              contest_instance: contest_instance,
              round_number: 2,
              start_date: first_round.end_date + 1.hour,
              end_date: first_round.end_date + 2.days)
      end

      it 'prevents completing a round if previous rounds are not completed' do
        expect(second_round.complete!).to be false
        expect(second_round.errors[:base]).to include('All previous rounds must be completed before completing this round')
        expect(second_round.reload.completed).to be false
      end

      it 'allows completing a round when previous rounds are completed' do
        first_round.complete!
        expect(second_round.complete!).to be true
        expect(second_round.reload.completed).to be true
      end

      it 'allows completing the first round regardless of other rounds' do
        expect(first_round.complete!).to be true
        expect(first_round.reload.completed).to be true
      end
    end
  end

  describe 'email tracking functionality' do
    let(:contest_instance) { create(:contest_instance) }
    let!(:first_round) do
      create(:judging_round,
             contest_instance: contest_instance,
             round_number: 1,
             start_date: contest_instance.date_closed + 1.day,
             end_date: contest_instance.date_closed + 2.days)
    end

    it 'defaults emails_sent_count to 0' do
      expect(first_round.emails_sent_count).to eq(0)
    end

    it 'increments emails_sent_count correctly' do
      expect {
        first_round.increment!(:emails_sent_count)
      }.to change { first_round.reload.emails_sent_count }.from(0).to(1)

      expect {
        first_round.increment!(:emails_sent_count)
      }.to change { first_round.reload.emails_sent_count }.from(1).to(2)
    end

    context 'with multiple rounds' do
      let!(:second_round) do
        create(:judging_round,
               contest_instance: contest_instance,
               round_number: 2,
               start_date: first_round.end_date + 1.hour,
               emails_sent_count: 0)
      end

      before do
        # Set first round to have some emails sent for testing
        first_round.update!(emails_sent_count: 2)
      end

      it 'tracks emails_sent_count independently for each round' do
        expect(first_round.reload.emails_sent_count).to eq(2)
        expect(second_round.emails_sent_count).to eq(0)

        second_round.increment!(:emails_sent_count)
        expect(second_round.reload.emails_sent_count).to eq(1)

        # Ensure first round count remains unchanged
        expect(first_round.reload.emails_sent_count).to eq(2)
      end
    end
  end
end
