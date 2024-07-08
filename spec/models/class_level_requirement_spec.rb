# == Schema Information
#
# Table name: class_level_requirements
#
#  id                  :bigint           not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  class_level_id      :bigint           not null
#  contest_instance_id :bigint           not null
#
# Indexes
#
#  index_class_level_requirements_on_class_level_id       (class_level_id)
#  index_class_level_requirements_on_contest_instance_id  (contest_instance_id)
#  index_clr_on_ci_and_cl                                 (contest_instance_id,class_level_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (class_level_id => class_levels.id)
#  fk_rails_...  (contest_instance_id => contest_instances.id)
#
require 'rails_helper'

RSpec.describe ClassLevelRequirement, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
