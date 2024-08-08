# frozen_string_literal: true

# == Schema Information
#
# Table name: assignments
#
#  id           :bigint           not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  container_id :bigint           not null
#  role_id      :bigint           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_assignments_on_container_id         (container_id)
#  index_assignments_on_role_id              (role_id)
#  index_assignments_on_role_user_container  (role_id,user_id,container_id) UNIQUE
#  index_assignments_on_user_id              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (container_id => containers.id)
#  fk_rails_...  (role_id => roles.id)
#  fk_rails_...  (user_id => users.id)
#
class Assignment < ApplicationRecord
  belongs_to :user
  belongs_to :container
  belongs_to :role

  validates :role_id,
            uniqueness: { scope: %i[user_id container_id],
                          message: 'combination with user and container must be unique' }
end
