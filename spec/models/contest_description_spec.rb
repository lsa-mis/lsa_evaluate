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
require 'rails_helper'

RSpec.describe ContestDescription do
  it { is_expected.to belong_to(:container) }
  it { is_expected.to belong_to(:status) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:short_name) }
  it { is_expected.to validate_presence_of(:eligibility_rules) }
  it { is_expected.to validate_presence_of(:created_by) }
end
