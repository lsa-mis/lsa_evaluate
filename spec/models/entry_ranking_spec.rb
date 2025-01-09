# == Schema Information
#
# Table name: entry_rankings
#
#  id                      :bigint           not null, primary key
#  external_comments       :text(65535)
#  finalized               :boolean          default(FALSE), not null
#  internal_comments       :text(65535)
#  notes                   :text(65535)
#  rank                    :integer
#  selected_for_next_round :boolean          default(FALSE), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  entry_id                :bigint           not null
#  judging_round_id        :bigint           not null
#  user_id                 :bigint           not null
#
# Indexes
#
#  index_entry_rankings_on_entry_id          (entry_id)
#  index_entry_rankings_on_judging_round_id  (judging_round_id)
#  index_entry_rankings_on_user_id           (user_id)
#  index_entry_rankings_uniqueness           (entry_id,judging_round_id,user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (entry_id => entries.id)
#  fk_rails_...  (judging_round_id => judging_rounds.id)
#  fk_rails_...  (user_id => users.id)
#
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
      shared_examples 'validates comment requirements' do |comment_type|
        let(:comment_field) { "#{comment_type}_comments" }
        let(:min_words_field) { "min_#{comment_type}_comment_words" }

        it 'is invalid without comments' do
          entry_ranking.send("#{comment_field}=", nil)
          expect(entry_ranking).not_to be_valid
          expect(entry_ranking.errors[comment_field]).to include('are required')
        end

        it 'is invalid with blank comments' do
          entry_ranking.send("#{comment_field}=", '')
          expect(entry_ranking).not_to be_valid
          expect(entry_ranking.errors[comment_field]).to include('are required')
        end

        context 'with minimum word requirement' do
          before do
            judging_round.update!(
              min_words_field => required_words,
              "require_#{comment_field}" => true
            )
          end

          let(:required_words) { comment_type == 'internal' ? 5 : 10 }

          it 'is invalid with too few words' do
            entry_ranking.send("#{comment_field}=", 'Too few words')
            expect(entry_ranking).not_to be_valid
            expect(entry_ranking.errors[comment_field]).to include("must be at least #{required_words} words")
          end

          it 'is valid with enough words' do
            long_comment = if comment_type == 'internal'
                            'This comment has five or more words here'
            else
                            'This external comment definitely has more than ten words to meet the requirement now'
            end

            entry_ranking.send("#{comment_field}=", long_comment)
            expect(entry_ranking).to be_valid
          end
        end
      end

      context 'when internal comments are required' do
        before do
          judging_round.update!(
            require_internal_comments: true,
            require_external_comments: false
          )
          entry_ranking.finalized = true
        end

        include_examples 'validates comment requirements', 'internal'
      end

      context 'when external comments are required' do
        before do
          judging_round.update!(
            require_internal_comments: false,
            require_external_comments: true
          )
          entry_ranking.finalized = true
        end

        include_examples 'validates comment requirements', 'external'
      end

      context 'when neither type of comments is required' do
        before do
          judging_round.update!(
            require_internal_comments: false,
            require_external_comments: false,
            min_internal_comment_words: 0,
            min_external_comment_words: 0
          )
          entry_ranking.finalized = true
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
