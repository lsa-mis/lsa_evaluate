# lib/custom_failure.rb
class CustomFailure < Devise::FailureApp
  def redirect_url
    if warden_message == :timeout
      root_path
    else
      super
    end
  end

  def flash_message
    if warden_message == :timeout
      'Your session has expired. Please log in again to continue.'
    else
      super
    end
  end

  # def respond
  #   if http_auth?
  #     http_auth
  #   else
  #     set_flash_message! :alert, flash_message
  #     redirect
  #   end
  # end
end
