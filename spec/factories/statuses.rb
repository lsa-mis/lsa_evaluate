# == Schema Information
#
# Table name: statuses
#
#  id          :bigint           not null, primary key
#  description :text(65535)
#  kind        :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do
  factory :status do
    kind { %w[Active Deleted Archived Disqualified].sample }
    description { Faker::Lorem.sentence(word_count: 5) }
  end
end
