# == Schema Information
#
# Table name: category_contest_instances
#
#  id                  :bigint           not null, primary key
#  category_id         :bigint           not null
#  contest_instance_id :bigint           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
class CategoryContestInstance < ApplicationRecord
  belongs_to :category
  belongs_to :contest_instance
end
