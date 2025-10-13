# frozen_string_literal: true

module AspaceVersionControl
  # This class is responsible for committing EADs and EACs to GitLab for version control
  class GitLab
    def initialize(repo_path: nil)
      @custom_repo_path = repo_path
    end

    def commit_eads_to_git(path:)
      pull
      return unless changes?(path:)
      add(path:)
      commit('monthly snapshot of ASpace EADs')
      push
    end

    def commit_eacs_to_git(path:)
      git_config
      update(path:)
      return unless changes?(path:)
      add(path:)
      commit('monthly snapshot of ASpace Agent EACs')
      push
    end

    def repo
      @repo ||=
        begin
          Git.clone(GitLab.git_uri, current_repo_path)
        rescue Git::Error, Git::FailedError
          Git.open(current_repo_path)
        end
    end

    def git_config
      configure_git_user(repo)
    end

    def current_repo_path
      @custom_repo_path || GitLab.git_repo_path
    end

    def update(path:)
      repo.checkout('HEAD', path:)
      pull
    end

    delegate :pull, to: :repo

    def add(path:)
      repo.add(path)
    end

    def commit(message = 'monthly snapshot of ASpace EADs')
      repo.commit(message)
    end

    delegate :push, to: :repo

    def changes?(path:)
      repo_status = repo.status
      changed = repo_status.changed.present? || repo_status.untracked.present?
      return true if changed
      Rails.logger.info("No changes present for #{path}")
      false
    end

    def self.git_uri
      @git_uri ||= "git@#{config.git_lab_host}:#{config.git_lab_source_path}.git"
    end

    def self.git_repo_path
      @git_repo_path ||= ENV['GIT_LAB_DIR'] || config.local_git_lab_dir
    end

    def self.git_repo_eacs_path
      @git_repo_eacs_path ||= config.local_git_lab_eacs_dir
    end

    def self.config
      @config ||= Rails.application.config.aspace
    end

    private

    def configure_git_user(repo)
      repo.config('user.name', 'scuaAPI')
      repo.config('user.email', 'heberlen@princeton.edu')
    end
  end
end
