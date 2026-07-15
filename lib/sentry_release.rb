# frozen_string_literal: true

# Resolves a deploy-specific release id for Sentry (git SHA preferred).
module SentryRelease
  module_function

  def current
    ENV['SENTRY_RELEASE'].presence ||
      revision_file.presence ||
      git_sha.presence
  end

  def revision_file
    path = Rails.root.join('REVISION')
    return unless path.file?

    path.read.strip.presence
  end
  private_class_method :revision_file

  def git_sha
    sha = `git rev-parse HEAD 2>/dev/null`.strip
    sha.presence
  rescue StandardError
    nil
  end
  private_class_method :git_sha
end
