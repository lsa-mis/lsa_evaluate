class ActiveApplicantsReportService
  def initialize(container:, contest_descriptions:)
    @container = container
    @active_contest_descriptions = contest_descriptions
  end

  def call
    # Get all active entries for the specified contest descriptions
    # Use distinct to avoid duplicate profiles
    Profile
      .joins(:entries)
      .joins('INNER JOIN contest_instances ON entries.contest_instance_id = contest_instances.id')
      .joins('INNER JOIN contest_descriptions ON contest_instances.contest_description_id = contest_descriptions.id')
      .joins(:user)
      .where(
        entries: { deleted: false, disqualified: false },
        contest_descriptions: {
          id: @active_contest_descriptions.map(&:id),
          active: true
        },
        contest_instances: {
          active: true
        }
      )
      .select('DISTINCT profiles.*, users.first_name, users.last_name, users.email')
      .order('users.last_name, users.first_name')
  end
end
