# frozen_string_literal: true
module Aspace2alma
  # retry transient network errors
  module Retries
    # retries per call
    RETRY_ATTEMPTS = 3
    # connection errors
    NETWORK_ERRORS = [Errno::ECONNRESET, Errno::ECONNABORTED, Errno::ETIMEDOUT, Errno::ECONNREFUSED].freeze
    # ArchivesSpace errors worth retrying
    ASPACE_ERRORS = [Net::ReadTimeout, Net::OpenTimeout, *NETWORK_ERRORS].freeze
    # sftp errors worth retrying
    SFTP_ERRORS = [Net::SSH::Disconnect, Net::SSH::ConnectionTimeout, *NETWORK_ERRORS].freeze

    private

    # retry, then re-raise
    def with_retries(errors, description)
      attempt = 0
      begin
        yield
      rescue *errors => error
        attempt += 1
        raise if attempt > RETRY_ATTEMPTS

        Rails.logger.warn("#{self.class}: #{error.class} ('#{error.message}') while #{description}, " \
                          "retry #{attempt} of #{RETRY_ATTEMPTS} in #{attempt} second(s)")
        sleep(attempt)
        retry
      end
    end
  end
end
