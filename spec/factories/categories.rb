# == Schema Information
#
# Table name: categories
#
#  id          :bigint           not null, primary key
#  kind        :string(255)
#  description :text(65535)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do
  factory :category do
    sequence(:kind) { |n| "Category #{n}" }
    description { Faker::Lorem.sentence(word_count: 5) }

    # General category
    trait :general do
      kind { 'General' }
    end

    # Drama category
    trait :drama do
      kind { 'Drama' }
    end

    # Fiction category
    trait :fiction do
      kind { 'Fiction' }
    end

    # Poetry category
    trait :poetry do
      kind { 'Poetry' }
    end

    # Non-Fiction category
    trait :non_fiction do
      kind { 'Non-Fiction' }
    end
  end
end
