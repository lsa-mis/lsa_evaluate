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
class Visibility < ApplicationRecord
  # validates :kind, presence: true, uniqueness: true
end
