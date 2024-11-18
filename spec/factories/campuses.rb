# == Schema Information
#
# Table name: campuses
#
#  id           :bigint           not null, primary key
#  campus_descr :string(255)      not null
#  campus_cd    :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
FactoryBot.define do
  factory :campus do
    sequence(:campus_cd) { |n| "CAMPUS_CD_#{n}" }
    sequence(:campus_descr) { |n| "Campus Description #{n}" }

    trait :predefined do
      campus_cd { '1001' }
      campus_descr { 'AnnArbor' }
    end
  end
end
