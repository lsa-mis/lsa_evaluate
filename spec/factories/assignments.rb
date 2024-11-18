# == Schema Information
#
# Table name: assignments
#
#  id           :bigint           not null, primary key
#  user_id      :bigint           not null
#  container_id :bigint           not null
#  role_id      :bigint           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
FactoryBot.define do
  factory :assignment do
    user
    container
    role
  end
end
