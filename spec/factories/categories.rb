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
# spec/factories/categories.rb
FactoryBot.define do
  factory :category_drama, class: 'Category' do
    kind { 'Drama' }
    description { Faker::Lorem.sentence(word_count: 5) }
  end
end
