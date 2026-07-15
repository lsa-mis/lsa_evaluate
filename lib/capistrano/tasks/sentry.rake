# frozen_string_literal: true

namespace :sentry do
  desc 'Write REVISION file so Rails can report a deploy-specific Sentry release'
  task :write_revision do
    on roles(:app) do
      revision = fetch(:current_revision)
      upload! StringIO.new(revision), "#{release_path}/REVISION"
    end
  end

  desc 'Notify Sentry of a new deploy (requires SENTRY_AUTH_TOKEN, SENTRY_ORG, SENTRY_PROJECT)'
  task :notify_deploy do
    auth_token = ENV['SENTRY_AUTH_TOKEN']
    org = ENV['SENTRY_ORG']
    project = ENV['SENTRY_PROJECT']
    next unless auth_token.present? && org.present? && project.present?

    revision = fetch(:current_revision)
    environment = fetch(:rails_env, 'production')

    run_locally do
      execute :curl, '-sS', '-X', 'POST',
              "https://sentry.io/api/0/organizations/#{org}/releases/",
              '-H', "Authorization: Bearer #{auth_token}",
              '-H', 'Content-Type: application/json',
              '-d', "'{\"version\":\"#{revision}\",\"projects\":[\"#{project}\"]}'"

      execute :curl, '-sS', '-X', 'POST',
              "https://sentry.io/api/0/organizations/#{org}/releases/#{revision}/deploys/",
              '-H', "Authorization: Bearer #{auth_token}",
              '-H', 'Content-Type: application/json',
              '-d', "'{\"environment\":\"#{environment}\"}'"
    end
  end
end

after 'deploy:updated', 'sentry:write_revision'
after 'deploy:finished', 'sentry:notify_deploy'
