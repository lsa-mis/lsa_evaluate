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
  factory :status_active, class: 'Status' do
    kind { 'Active' }
    description { Faker::Lorem.sentence(word_count: 5) }
  end

  factory :status_archived, class: 'Status' do
    kind { 'Archived' }
    description { Faker::Lorem.sentence(word_count: 5) }
  end
end
