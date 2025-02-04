# frozen_string_literal: true

# Pagy initializer file
# See https://ddnexus.github.io/pagy/api/pagy#configuration

require 'pagy/extras/bootstrap'  # Add bootstrap extra for styled pagination
require 'pagy/extras/items'      # Allow users to change the number of items per page

Pagy::DEFAULT[:items] = 20        # Default items per page
Pagy::DEFAULT[:max_items] = 100   # Max items per page to prevent abuse
