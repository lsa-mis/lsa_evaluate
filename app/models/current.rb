# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  # Hash of contest_instance_id (string) => access_token that was redeemed
  attribute :redeemed_contest_instances
end
