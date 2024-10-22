# == Schema Information
#
# Table name: contest_descriptions
#
#  id           :bigint           not null, primary key
#  active       :boolean          default(FALSE), not null
#  archived     :boolean          default(FALSE), not null
#  created_by   :string(255)      not null
#  name         :string(255)      not null
#  short_name   :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  container_id :bigint           not null
#
# Indexes
#
#  index_contest_descriptions_on_container_id  (container_id)
#
# Foreign Keys
#
#  fk_rails_...  (container_id => containers.id)
#
class ContestDescription < ApplicationRecord
  belongs_to :container
  has_many :contest_instances, dependent: :restrict_with_error

  has_rich_text :eligibility_rules
  has_rich_text :notes

  accepts_nested_attributes_for :contest_instances, allow_destroy: true

  validates :created_by, presence: true
  validates :name, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }
  scope :archived, -> { where(archived: true) }

  def self.create_multiple_instances(contest_descriptions, params, current_user)
    success_count = 0
    errors = []

    ApplicationRecord.transaction do
      contest_descriptions.each do |description|
        instance = description.contest_instances.new(params)
        instance.created_by = current_user.email

        if instance.save
          success_count += 1
        else
          errors << "Failed to create instance for '#{description.name}': #{instance.errors.full_messages.join(', ')}"
        end
      end

      raise ActiveRecord::Rollback if errors.any?
    end

    { success: errors.empty?, count: success_count, errors: errors }
  end
end
