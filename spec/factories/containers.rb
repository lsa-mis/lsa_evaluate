# == Schema Information
#
# Table name: containers
#
#  id            :bigint           not null, primary key
#  name          :string(255)
#  notes         :text(65535)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  department_id :bigint           not null
#  visibility_id :bigint           not null
#
# Indexes
#
#  index_containers_on_department_id  (department_id)
#  index_containers_on_visibility_id  (visibility_id)
#
# Foreign Keys
#
#  fk_rails_...  (department_id => departments.id)
#  fk_rails_...  (visibility_id => visibilities.id)
#
FactoryBot.define do
  factory :container do
    sequence(:name) { |n| "Container #{n}" }
    sequence(:description) { |n| "Description for Container #{n}" }
    department
    visibility
    notes { "Notes for #{name}" }
  end
end
