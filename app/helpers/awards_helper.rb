# frozen_string_literal: true

module AwardsHelper
  PLACEMENT_OPTIONS = (1..10).map { |number| [ number.ordinalize, number ] }.freeze

  def award_status_options
    [
      [ 'Unawarded', 'unawarded' ],
      [ 'Winner', 'winner' ],
      [ 'Finalist', 'finalist' ]
    ]
  end

  def placement_options
    [ [ '—', '' ] ] + PLACEMENT_OPTIONS
  end

  def format_award_amount(amount)
    return '—' if amount.blank?

    number_to_currency(amount)
  end

  def assignable_catalog_awards(entry, catalog_awards)
    assigned_ids = entry.entry_awards.map(&:award_id)
    has_primary = entry.entry_awards.any?(&:primary?)

    catalog_awards.reject do |award|
      assigned_ids.include?(award.id) || (award.primary? && has_primary)
    end
  end

  def suggested_for_award?(entry, contest_instance)
    contest_instance.last_round_selected_entry_ids.include?(entry.id)
  end

  def entry_prizes_summary(entry)
    names = entry.entry_awards.filter_map { |entry_award| entry_award.award&.name }
    return '—' if names.empty?

    names.join(', ')
  end
end
