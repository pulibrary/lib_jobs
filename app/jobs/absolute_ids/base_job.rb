# frozen_string_literal: true
module AbsoluteIds
  class BaseJob < ::ApplicationJob
    private

    def current_user
      @current_user ||= ::User.find_by(id: @user_id)
    end

    def current_client
      @current_client ||= begin
                            source_client = LibJobs::ArchivesSpace::Client.source
                            source_client.login
                            source_client
                          end
    end
  end
end
