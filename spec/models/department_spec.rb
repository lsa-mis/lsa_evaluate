# == Schema Information
#
# Table name: departments
#
#  id               :bigint           not null, primary key
#  dept_description :text(65535)
#  name             :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  dept_id          :integer          not null
#
require 'rails_helper'

RSpec.describe Department do
  pending "add some examples to (or delete) #{__FILE__}"
end
