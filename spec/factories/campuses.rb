# == Schema Information
#
# Table name: campuses
#
#  id           :bigint           not null, primary key
#  campus_cd    :integer          not null
#  campus_descr :string(255)      not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  campus_cd_unq_idx     (campus_cd) UNIQUE
#  campus_descr_idx      (campus_descr)
#  campus_descr_unq_idx  (campus_descr) UNIQUE
#  id_unq_idx            (id) UNIQUE
#
FactoryBot.define do
  factory :campus do
    campus_descr { Faker::Address.community }
    campus_cd { Faker::Number.unique.number(digits: 4) }
  end
end
