# Allow anonymous (signed-out) visitors to submit feedback.
#
# LsaTdxFeedback::FeedbackController inherits from the host ApplicationController,
# which runs `before_action :authenticate_user!`. The feedback modal is rendered
# on public pages, so unauthenticated submissions were being rejected with a
# 401 Unauthorized. Skipping the Devise authentication callback on this engine
# controller lets feedback be submitted regardless of sign-in state.
Rails.application.config.to_prepare do
  LsaTdxFeedback::FeedbackController.class_eval do
    skip_before_action :authenticate_user!, raise: false
  end
end
