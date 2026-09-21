# == Schema Information
#
# Table name: categories
#
#  id           :bigint           not null, primary key
#  description  :text(65535)
#  kind         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  container_id :bigint           not null
#
# Indexes
#
#  index_categories_on_container_id           (container_id)
#  index_categories_on_container_id_and_kind  (container_id,kind) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (container_id => containers.id)
#
FactoryBot.define do
  factory :category do
    association :container
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
