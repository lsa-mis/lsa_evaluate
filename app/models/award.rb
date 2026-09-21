# frozen_string_literal: true

# == Schema Information
#
# Table name: awards
#
#  id                :bigint           not null, primary key
#  active            :boolean          default(TRUE), not null
#  default_amount    :decimal(10, 2)
#  default_shortcode :string(255)
#  description       :text(65535)
#  kind              :string(255)      default("primary"), not null
#  name              :string(255)      not null
#  position          :integer          default(0), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  container_id      :bigint           not null
#
class Award < ApplicationRecord
  KINDS = {
    primary: 'primary',
    add_on: 'add_on'
  }.freeze

  KIND_LABELS = {
    'primary' => 'Primary prize',
    'add_on' => 'Add-on prize'
  }.freeze

  belongs_to :container
  has_many :entry_awards, dependent: :restrict_with_error

  enum :kind, KINDS, default: :primary, validate: true

  validates :name, presence: true
  validates :name, uniqueness: { scope: :container_id, case_sensitive: false }
  validates :kind, presence: true
  validates :default_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :kind_not_changed_when_assigned

  before_validation :assign_position, on: :create

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name, :id) }

  def kind_label
    KIND_LABELS.fetch(kind, kind.to_s.humanize)
  end

  def kind_locked?
    persisted? && assigned?
  end

  def assigned?
    if entry_awards.loaded?
      entry_awards.any?
    else
      entry_awards.exists?
    end
  end

  def self.kind_options
    KIND_LABELS.map { |value, label| [ label, value ] }
  end

  private

  def kind_not_changed_when_assigned
    return unless will_save_change_to_kind?
    return unless assigned?

    errors.add(:kind, 'cannot be changed after the prize has been assigned')
  end

  def assign_position
    return unless new_record?
    return if position.present? && position.positive?

    max_position = Award.where(container_id: container_id).maximum(:position)
    self.position = max_position.nil? ? 0 : max_position + 1
  end
end
