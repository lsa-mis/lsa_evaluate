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
  has_many :contest_instances
  validates :kind, presence: true,
                   inclusion: { in: ['Drama', 'Screenplay', 'Non-Fiction',
                                     'Fiction', 'Poetry', 'Novel',
                                     'Short Fiction', 'Text-Image'] },
                   uniqueness: true
  validates :description, presence: true
end
