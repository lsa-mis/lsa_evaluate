# == Schema Information
#
# Table name: affiliations
#
#  id         :bigint           not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_affiliations_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
# spec/factories/affiliations.rb
FactoryBot.define do
  factory :affiliation do
    name { "employee" }  # Default value, can be overridden in tests
    user    # This links the affiliation to a user
  end
end
