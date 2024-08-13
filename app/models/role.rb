# frozen_string_literal: true

# == Schema Information
#
# Table name: roles
#
#  id          :bigint           not null, primary key
#  description :text(65535)
#  kind        :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Role < ApplicationRecord
  has_many :containers, through: :assignments

  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles
  has_many :assignments, dependent: :destroy

  def display_name
    kind
  end
end
