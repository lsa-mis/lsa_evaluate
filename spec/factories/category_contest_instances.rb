# == Schema Information
#
# Table name: category_contest_instances
#
#  id                  :bigint           not null, primary key
#  category_id         :bigint           not null
#  contest_instance_id :bigint           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
FactoryBot.define do
  factory :category_contest_instance do
    category
    contest_instance
  end
end
