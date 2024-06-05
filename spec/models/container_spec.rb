# == Schema Information
#
# Table name: containers
#
#  id            :bigint           not null, primary key
#  description   :text(65535)
#  name          :string(255)
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
require 'rails_helper'

RSpec.describe Container, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
