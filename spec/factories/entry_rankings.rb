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
FactoryBot.define do
  factory :entry_ranking do
    entry
    judging_round
    user { create(:user, :with_judge_role) }
    rank { rand(1..10) }
    notes { Faker::Lorem.paragraph }
    internal_comments { Faker::Lorem.paragraph(sentence_count: 3) }
    external_comments { Faker::Lorem.paragraph(sentence_count: 3) }
    selected_for_next_round { false }

    trait :selected do
      selected_for_next_round { true }
    end

    trait :with_assigned_judge do
      after(:build) do |entry_ranking|
        create(:judging_assignment,
          user: entry_ranking.user,
          contest_instance: entry_ranking.judging_round.contest_instance,
          active: true
        )
        create(:round_judge_assignment,
          user: entry_ranking.user,
          judging_round: entry_ranking.judging_round,
          active: true
        )
      end
    end

    trait :with_minimal_comments do
      internal_comments { "Short internal note" }
      external_comments { "Short external note" }
    end

    trait :with_detailed_comments do
      internal_comments { Faker::Lorem.paragraph(sentence_count: 5) }
      external_comments { Faker::Lorem.paragraph(sentence_count: 5) }
    end
  end
end
