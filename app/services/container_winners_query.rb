# frozen_string_literal: true

class ContainerWinnersQuery
  def initialize(container:, contest_description_id: nil, contest_instance_id: nil, award_status: nil, award_kind: nil)
    @container = container
    @contest_description_id = contest_description_id.presence
    @contest_instance_id = contest_instance_id.presence
    @award_status = award_status.presence
    @award_kind = award_kind.presence
  end

  def entries
    scope = Entry.active
                 .merge(Entry.awarded)
                 .joins(:profile, contest_instance: { contest_description: :container })
                 .where(containers: { id: @container.id })
                 .includes(
                   :category,
                   { entry_awards: :award },
                   { profile: [ :user, :class_level, :school, :campus ] },
                   contest_instance: :contest_description
                 )
                 .order(
                   'contest_descriptions.name ASC',
                   'contest_instances.date_open DESC',
                   Arel.sql('entries.placement IS NULL, entries.placement ASC'),
                   'profiles.legal_last_name ASC',
                   'profiles.legal_first_name ASC'
                 )

    if @contest_description_id
      scope = scope.where(contest_descriptions: { id: @contest_description_id })
    end

    if @contest_instance_id
      scope = scope.where(contest_instances: { id: @contest_instance_id })
    end

    if @award_status
      scope = scope.where(award_status: @award_status)
    end

    if @award_kind
      scope = scope.joins(entry_awards: :award).where(awards: { kind: @award_kind }).distinct
    end

    scope
  end
end
