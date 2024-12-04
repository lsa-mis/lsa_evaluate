module JudgingAssignmentsHelper
  def display_email(email)
    if email.end_with?('@umich.edu') && email.include?('+')
      local_part, _domain = email.split('@')
      username, original_domain = local_part.split('+')
      "#{username}@#{original_domain}"
    else
      email
    end
  end
end
