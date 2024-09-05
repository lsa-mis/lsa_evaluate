# spec/factories/affiliations.rb
FactoryBot.define do
  factory :affiliation do
    name { "employee" }  # Default value, can be overridden in tests
    user    # This links the affiliation to a user
  end
end
