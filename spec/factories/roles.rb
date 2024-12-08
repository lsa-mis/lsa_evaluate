# == Schema Information
#
# Table name: roles
#
#  id          :bigint           not null, primary key
#  description :text(65535)
#  kind        :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do
  factory :role do
    sequence(:description) { |n| "Role Description #{n}" }
    kind { 'User' }  # Default kind

    trait :judge do
      kind { 'Judge' }
      description { 'Judge Role Description' }
    end

    trait :admin do
      kind { 'Collection Administrator' }
      description { 'Collection Administrator Role Description' }
    end

    trait :axis_mundi do
      kind { 'Axis mundi' }
      description { 'Axis mundi Role Description' }
    end
  end
end
