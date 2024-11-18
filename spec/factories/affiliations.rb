# == Schema Information
#
# Table name: affiliations
#
#  id         :bigint           not null, primary key
#  name       :string(255)
#  user_id    :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :affiliation do
    name { "employee" }  # Default value, can be overridden in tests
    user    # This links the affiliation to a user
  end
end
