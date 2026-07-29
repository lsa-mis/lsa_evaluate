# frozen_string_literal: true

module ContestInviteSession
  extend ActiveSupport::Concern

  REDEEMED_SESSION_KEY = :redeemed_contest_instances
  PENDING_SESSION_KEY = :pending_contest_invite_token

  included do
    before_action :load_redeemed_contest_instances_into_current
  end

  private

  def load_redeemed_contest_instances_into_current
    Current.redeemed_contest_instances = session[REDEEMED_SESSION_KEY] || {}
  end

  def redeem_contest_instance!(contest_instance)
    session[REDEEMED_SESSION_KEY] ||= {}
    session[REDEEMED_SESSION_KEY][contest_instance.id.to_s] = contest_instance.access_token
    Current.redeemed_contest_instances = session[REDEEMED_SESSION_KEY]
  end

  def remember_pending_contest_invite!(contest_instance)
    session[PENDING_SESSION_KEY] = contest_instance.access_token
  end

  def consume_pending_contest_invite_token
    session.delete(PENDING_SESSION_KEY)
  end

  def redeemed_token_for(contest_instance)
    Current.redeemed_contest_instances&.dig(contest_instance.id.to_s)
  end

  def contest_instance_redeemed?(contest_instance)
    redeemed_token_for(contest_instance) == contest_instance.access_token
  end
end
