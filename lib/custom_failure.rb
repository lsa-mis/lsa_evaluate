# lib/custom_failure.rb
class CustomFailure < Devise::FailureApp
  def redirect_url
    if warden_message == :timeout
      root_path
    else
      super
    end
  end

  # Devise 5 FailureApp sets flash via i18n_message (not flash_message).
  def i18n_message(default = nil)
    if warden_message == :timeout
      'Your session has expired. Please log in again to continue.'
    else
      super
    end
  end
end
