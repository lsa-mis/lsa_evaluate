# frozen_string_literal: true

# == Schema Information
#
# Table name: contest_invitations
#
#  id                  :bigint           not null, primary key
#  email               :string(255)      not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  contest_instance_id :bigint           not null
#  invited_by_id       :bigint
#
# Indexes
#
#  index_contest_invitations_on_contest_instance_id      (contest_instance_id)
#  index_contest_invitations_on_instance_and_email       (contest_instance_id,email) UNIQUE
#  index_contest_invitations_on_invited_by_id            (invited_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (contest_instance_id => contest_instances.id)
#  fk_rails_...  (invited_by_id => users.id)
#
class ContestInvitation < ApplicationRecord
  belongs_to :contest_instance
  belongs_to :invited_by, class_name: 'User', optional: true

  before_validation :normalize_email

  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { scope: :contest_instance_id, case_sensitive: false }

  scope :for_email, ->(email) { where(email: email.to_s.strip.downcase) }

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end
end
