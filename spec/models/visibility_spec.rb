# == Schema Information
#
# Table name: visibilities
#
#  id          :bigint           not null, primary key
#  description :text(65535)
#  kind        :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_visibilities_on_kind  (kind) UNIQUE
#
require 'rails_helper'

RSpec.describe Visibility do
  pending "add some examples to (or delete) #{__FILE__}"
end
