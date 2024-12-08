# == Schema Information
#
# Table name: categories
#
#  id          :bigint           not null, primary key
#  description :text(65535)
#  kind        :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_categories_on_kind  (kind) UNIQUE
#
FactoryBot.define do
  factory :category do
    sequence(:kind) { |n| "Category #{n}" }
    description { "Description for #{kind}" }

    trait :general do
      kind { 'General' }
    end

    trait :drama do
      kind { 'Drama' }
    end

    trait :fiction do
      kind { 'Fiction' }
    end

    trait :poetry do
      kind { 'Poetry' }
    end

    trait :non_fiction do
      kind { 'Non-Fiction' }
    end
  end
end
