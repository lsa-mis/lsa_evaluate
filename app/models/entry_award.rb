# frozen_string_literal: true

# == Schema Information
#
# Table name: entry_awards
#
#  id         :bigint           not null, primary key
#  amount     :decimal(10, 2)
#  notes      :text(65535)
#  shortcode  :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  award_id   :bigint           not null
#  entry_id   :bigint           not null
#
class EntryAward < ApplicationRecord
  belongs_to :entry
  belongs_to :award

  validates :award_id, uniqueness: { scope: :entry_id }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :award_belongs_to_entry_container
  validate :one_primary_prize_per_entry
  validate :award_is_active, on: :create

  before_validation :copy_defaults_from_award, on: :create

  scope :primary, -> { joins(:award).where(awards: { kind: Award.kinds[:primary] }) }
  scope :add_on, -> { joins(:award).where(awards: { kind: Award.kinds[:add_on] }) }

  delegate :primary?, :add_on?, :name, to: :award, prefix: true, allow_nil: true

  def primary?
    award&.primary?
  end

  def add_on?
    award&.add_on?
  end

  private

  def copy_defaults_from_award
    return unless award

    self.amount = award.default_amount if amount.nil?
    self.shortcode = award.default_shortcode if shortcode.nil?
  end

  def award_belongs_to_entry_container
    return unless award && entry

    container_id = entry.contest_instance.contest_description.container_id
    return if award.container_id == container_id

    errors.add(:award, 'must belong to the same collection as this entry')
  end

  def one_primary_prize_per_entry
    return unless award&.primary? && entry

    existing = entry.entry_awards.joins(:award).where(awards: { kind: Award.kinds[:primary] })
    existing = existing.where.not(id: id) if persisted?
    return unless existing.exists?

    errors.add(:award, 'already has a primary prize assigned')
  end

  def award_is_active
    return unless award
    return if award.active?

    errors.add(:award, 'is not active in the collection catalog')
  end
end
