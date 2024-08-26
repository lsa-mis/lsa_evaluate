# == Schema Information
#
# Table name: categories
#
#  id          :bigint           not null, primary key
#  description :text(65535)
#  kind        :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_categories_on_kind  (kind) UNIQUE
#
class Category < ApplicationRecord
  has_many :category_contest_instances
  has_many :contest_instances, through: :category_contest_instances
  validates :kind, presence: true,
                   uniqueness: true
  validates :description, presence: true
end
