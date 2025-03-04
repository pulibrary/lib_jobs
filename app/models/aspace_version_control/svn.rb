# frozen_string_literal: true

module AspaceVersionControl
  # This class is responsible for committing EADs to SVN for version control
  class Svn
    attr_reader :local_svn_dir, :svn_username, :svn_password, :errors

    def commit_eads_to_svn(path: nil)
      svn_update
      svn_add
      svn_commit(path:)
      errors
    end

    def initialize
      config = Rails.application.config.aspace
      @local_svn_dir = config.local_svn_dir
      @svn_username = config.svn_username
      @svn_password = config.svn_password
      @errors = []
    end

    private

    def svn_update
      capture_output = Open3.capture3("svn update #{local_svn_dir}")
      failure_comment = "Update failed"
      log_svn(capture_output, failure_comment)
    end

    def svn_add
      capture_output = Open3.capture3("svn add --force #{local_svn_dir}")
      failure_comment = "SVN Add failed"
      log_svn(capture_output, failure_comment)
    end

    def svn_commit(path: nil)
      command = "svn commit #{local_svn_dir}/#{path} -m 'monthly snapshot of ASpace EADs' --username #{svn_username} --password #{svn_password}"
      capture_output = Open3.capture3(command)
      failure_comment = "Commit failed"
      log_svn(capture_output, failure_comment)
    end

    def log_svn(capture_output, failure_comment)
      stdout_str, stderr_str, status = capture_output
      Rails.logger.info(stdout_str) unless stdout_str.empty?
      @errors << stderr_str unless stderr_str.empty?
      return unless status.success? == false
      @errors << failure_comment
    end
  end
end
