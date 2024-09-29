# == Schema Information
#
# Table name: contest_descriptions
#
#  id           :bigint           not null, primary key
#  active       :boolean          default(FALSE), not null
#  archived     :boolean          default(FALSE), not null
#  created_by   :string(255)      not null
#  name         :string(255)      not null
#  short_name   :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  container_id :bigint           not null
#
# Indexes
#
#  index_contest_descriptions_on_container_id  (container_id)
#
# Foreign Keys
#
#  fk_rails_...  (container_id => containers.id)
#
FactoryBot.define do
  factory :contest_description do
    container
    name { Faker::Lorem.word }
    short_name { Faker::Lorem.word }
    after(:build) do |contest_description|
      contest_description.eligibility_rules = ActionText::RichText.new(body: Faker::Lorem.paragraph)
    end

    after(:build) do |contest_description|
      contest_description.notes = ActionText::RichText.new(body: Faker::Lorem.paragraph)
    end

    created_by { Faker::Name.name }
  end
end
