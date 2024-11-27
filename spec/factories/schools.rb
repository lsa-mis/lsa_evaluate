# == Schema Information
#
# Table name: schools
#
#  id         :bigint           not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  id_unq_idx  (id) UNIQUE
#
FactoryBot.define do
  factory :school do
    name { Faker::Educator.university }
  end
end
