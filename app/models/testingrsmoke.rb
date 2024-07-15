# == Schema Information
#
# Table name: testingrsmokes
#
#  id         :bigint           not null, primary key
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Testingrsmoke < ApplicationRecord
  validates :name, presence: true, uniqueness: true
end
