# frozen_string_literal: true

# Devise already protects the /jobs mount; disable Mission Control HTTP basic auth.
MissionControl::Jobs.http_basic_auth_enabled = false
