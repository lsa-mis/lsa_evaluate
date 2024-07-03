# == Schema Information
#
# Table name: contest_descriptions
#
#  id                :bigint           not null, primary key
#  created_by        :string(255)      not null
#  eligibility_rules :text(65535)
#  name              :string(255)      not null
#  notes             :text(65535)
#  short_name        :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  container_id      :bigint           not null
#  status_id         :bigint           not null
#
# Indexes
#
#  index_contest_descriptions_on_container_id  (container_id)
#  index_contest_descriptions_on_status_id     (status_id)
#
# Foreign Keys
#
#  fk_rails_...  (container_id => containers.id)
#  fk_rails_...  (status_id => statuses.id)
#
FactoryBot.define do
  factory :contest_description do
    association :container
    association :status
    name { Faker::Lorem.word }
    short_name { Faker::Lorem.word }
    eligibility_rules { Faker::Lorem.paragraph }
    notes { Faker::Lorem.paragraph }
    created_by { Faker::Name.name }
  end
end
