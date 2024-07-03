# == Schema Information
#
# Table name: departments
#
#  id               :bigint           not null, primary key
#  dept_description :text(65535)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  dept_id          :integer
#
require 'rails_helper'

RSpec.describe Department do
  pending "add some examples to (or delete) #{__FILE__}"
end
