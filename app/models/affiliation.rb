# == Schema Information
#
# Table name: affiliations
#
#  id         :bigint           not null, primary key
#  name       :string(255)
#  user_id    :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Affiliation < ApplicationRecord
  belongs_to :user
  validates :name, presence: true
end
