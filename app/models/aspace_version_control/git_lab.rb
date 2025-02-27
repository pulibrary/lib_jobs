# frozen_string_literal: true

module AspaceVersionControl
  # This class is responsible for committing EADs to GitLab for version control
  class GitLab
    def commit_eads_to_git(path:)
      git_base
      byebug
      git_base.pull
    end

    def self.git_uri
      @git_uri ||= begin
        host = config.gitlab_host
        source_path = config.gitlab_source_path
        "git@#{host}:#{source_path}.git"
      end
    end

    def self.destination_path
      @destination_path ||= begin
        config.gitlab_destination_path
      end
    end

    def self.config
      @config ||= Rails.application.config.aspace
    end

    private

    def git_base
      @git_base ||= begin
        Git.clone(GitLab.git_uri, GitLab.destination_path)
      rescue Git::FailedError
        Git.open(GitLab.destination_path)
      end
    end
  end
end
