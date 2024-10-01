module ApplicantDashboardHelper
  def display_eligibility_rules(contest)
    eligibility_plain = contest.contest_description.eligibility_rules.to_plain_text
    if eligibility_plain.length > 100
      truncate(eligibility_plain, length: 100) +
      ' ' +
      link_to('...more', '#',
              data: { action: 'click->eligibility-modal#open',
                      url: eligibility_rules_container_contest_description_path(contest.contest_description.container, contest.contest_description) })
    else
      contest.contest_description.eligibility_rules
    end
  end
end
