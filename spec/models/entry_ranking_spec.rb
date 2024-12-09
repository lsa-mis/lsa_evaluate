require 'rails_helper'

RSpec.describe EntryRanking, type: :model do
  let(:contest_instance) { create(:contest_instance) }
  let(:judging_round) { create(:judging_round, contest_instance: contest_instance) }
  let(:entry) { create(:entry, contest_instance: contest_instance) }
  let(:judge) { create(:user, :with_judge_role) }
  let!(:judging_assignment) { create(:judging_assignment, user: judge, contest_instance: contest_instance) }

  describe 'validations' do
    subject(:entry_ranking) do
      build(:entry_ranking,
        entry: entry,
        judging_round: judging_round,
        user: judge,
        rank: 1
      )
    end

    it 'is valid with valid attributes' do
      expect(entry_ranking).to be_valid
    end

    describe 'rank validations' do
      it 'is valid with a positive integer rank' do
        entry_ranking.rank = 1
        expect(entry_ranking).to be_valid
      end

      it 'is invalid with a negative rank' do
        entry_ranking.rank = -1
        expect(entry_ranking).not_to be_valid
        expect(entry_ranking.errors[:rank]).to include('must be greater than 0')
      end

      it 'is invalid with a non-integer rank' do
        entry_ranking.rank = 1.5
        expect(entry_ranking).not_to be_valid
        expect(entry_ranking.errors[:rank]).to include('must be an integer')
      end

      it 'is valid when rank is nil' do
        entry_ranking.rank = nil
        expect(entry_ranking).to be_valid
      end
    end

    describe 'uniqueness validation' do
      before { create(:entry_ranking, entry: entry, judging_round: judging_round, user: judge) }

      it 'is invalid if entry is already ranked by the same judge in the same round' do
        duplicate_ranking = build(:entry_ranking, entry: entry, judging_round: judging_round, user: judge)
        expect(duplicate_ranking).not_to be_valid
        expect(duplicate_ranking.errors[:entry_id]).to include('has already been ranked by this judge in this round')
      end
    end

    describe 'comment validations' do
      context 'when internal comments are required' do
        before do
          judging_round.update(
            require_internal_comments: true,
            require_external_comments: false
          )
        end

        it 'is invalid without internal comments' do
          entry_ranking.internal_comments = nil
          expect(entry_ranking).not_to be_valid
          expect(entry_ranking.errors[:internal_comments]).to include('are required')
        end

        it 'is invalid with blank internal comments' do
          entry_ranking.internal_comments = ''
          expect(entry_ranking).not_to be_valid
          expect(entry_ranking.errors[:internal_comments]).to include('are required')
        end

        context 'with minimum word requirement' do
          before do
            judging_round.update(
              min_internal_comment_words: 5,
              min_external_comment_words: 0
            )
          end

          it 'is invalid with too few words' do
            entry_ranking.internal_comments = 'Too few words'
            expect(entry_ranking).not_to be_valid
            expect(entry_ranking.errors[:internal_comments]).to include('must contain at least 5 words')
          end

          it 'is valid with enough words' do
            entry_ranking.internal_comments = 'This comment has five or more words'
            expect(entry_ranking).to be_valid
          end
        end
      end

      context 'when external comments are required' do
        before do
          judging_round.update(
            require_internal_comments: false,
            require_external_comments: true
          )
        end

        it 'is invalid without external comments' do
          entry_ranking.external_comments = nil
          expect(entry_ranking).not_to be_valid
          expect(entry_ranking.errors[:external_comments]).to include('are required')
        end

        it 'is invalid with blank external comments' do
          entry_ranking.external_comments = ''
          expect(entry_ranking).not_to be_valid
          expect(entry_ranking.errors[:external_comments]).to include('are required')
        end

        context 'with minimum word requirement' do
          before do
            judging_round.update(
              min_internal_comment_words: 0,
              min_external_comment_words: 10
            )
          end

          it 'is invalid with too few words' do
            entry_ranking.external_comments = 'This comment is too short'
            expect(entry_ranking).not_to be_valid
            expect(entry_ranking.errors[:external_comments]).to include('must contain at least 10 words')
          end

          it 'is valid with enough words' do
            entry_ranking.external_comments = 'This comment has ten or more words which meets the requirement'
            expect(entry_ranking).to be_valid
          end
        end
      end

      context 'when neither type of comments is required' do
        before do
          judging_round.update(
            require_internal_comments: false,
            require_external_comments: false,
            min_internal_comment_words: 0,
            min_external_comment_words: 0
          )
        end

        it 'is valid without any comments' do
          entry_ranking.internal_comments = nil
          entry_ranking.external_comments = nil
          expect(entry_ranking).to be_valid
        end

        it 'is valid with only internal comments' do
          entry_ranking.internal_comments = 'Internal comment'
          entry_ranking.external_comments = nil
          expect(entry_ranking).to be_valid
        end

        it 'is valid with only external comments' do
          entry_ranking.internal_comments = nil
          entry_ranking.external_comments = 'External comment'
          expect(entry_ranking).to be_valid
        end
      end
    end
  end
end
