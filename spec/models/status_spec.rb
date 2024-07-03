# == Schema Information
#
# Table name: statuses
#
#  id          :bigint           not null, primary key
#  description :text(65535)
#  kind        :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe Status, type: :model do
  it { is_expected.to validate_presence_of(:kind) }
  it { is_expected.to validate_uniqueness_of(:kind) }
  it { is_expected.to validate_inclusion_of(:kind).in_array(%w[Active Deleted Archived Disqualified]) }
  it { is_expected.to validate_presence_of(:description) }
end
