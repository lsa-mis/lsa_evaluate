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
# Indexes
#
#  index_statuses_on_kind  (kind) UNIQUE
#
FactoryBot.define do
  factory :status do
    kind { 'Active' }
    description { Faker::Lorem.sentence(word_count: 5) }

    # General category
    trait :active do
      kind { 'Active' }
    end

    # Drama category
    trait :archived do
      kind { 'Archived' }
    end
  end
end
