#!/bin/bash
bundle exec rails db:create db:schema:load && \
  rails assets:precompile
