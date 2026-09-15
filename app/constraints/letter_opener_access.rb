# frozen_string_literal: true

# Gates the Letter Opener Web inbox. Development stays local and open;
# staging requires an axis mundi session so invite tokens are not public.
class LetterOpenerAccess
  def self.allowed?(user, env: Rails.env)
    case env.to_s
    when 'development'
      true
    when 'staging'
      user.respond_to?(:axis_mundi?) && user.axis_mundi?
    else
      false
    end
  end
end
