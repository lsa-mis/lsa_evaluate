# == Schema Information
#
# Table name: categories
#
#  id          :bigint           not null, primary key
#  kind        :string(255)
#  description :text(65535)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Category < ApplicationRecord
  has_many :category_contest_instances
  has_many :contest_instances, through: :category_contest_instances
  has_many :entries
  validates :kind, presence: true,
                   uniqueness: true
  validates :description, presence: true
end
