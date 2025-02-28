# frozen_string_literal: true

module AspaceVersionControl
  # This class is responsible for committing EADs to GitLab for version control
  class GitLab
    def commit_eads_to_git(path:)
      update
      return unless changes?(path:)
      add(path:)
      commit
      push
    end

    def repo
      @repo ||=
        begin
          Git.clone(GitLab.git_uri, GitLab.git_repo_path)
        rescue Git::Error
          Git.open(GitLab.git_repo_path)
        end
    end

    def update
      repo.pull
    end

    def add(path:)
      repo.add(path)
    end

    def commit
      repo.commit('monthly snapshot of ASpace EADs')
    end

    delegate :push, to: :repo

    def changes?(path:)
      changed = repo.status.changed?(path) || repo.status.untracked?(path)
      return changed if changed
      Rails.logger.info("No changes present for #{path}")
    end

    def self.git_uri
      @git_uri ||= "git@#{config.git_lab_host}:#{config.git_lab_source_path}.git"
    end

    def self.git_repo_path
      @git_repo_path ||= config.git_lab_local_repo_path
    end

    def self.config
      @config ||= Rails.application.config.aspace
    end
  end
end
