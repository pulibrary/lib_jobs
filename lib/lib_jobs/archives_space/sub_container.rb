# frozen_string_literal: true

module LibJobs
  module ArchivesSpace
    class SubContainer < Object
      # These are nested objects
      def initialize(attributes)
        normalized = attributes.deep_symbolize_keys
        @values = OpenStruct.new(normalized)

        @repository = @values.repository

        @create_time = @values.create_time
        @system_mtime = @values.system_mtime
        @user_mtime = @values.user_mtime
        @lock_version = @values.lock_version
      end

      def top_container
        @top_container_resource ||= begin
                                      return unless @values.top_container

                                      top_container_uri = @values.top_container[:ref]
                                      return unless top_container_uri

                                      @repository.find_top_container_by(uri: top_container_uri)
                                    end
      end

      def top_container=(updated)
        @top_container_resource = updated
        @values.to_h[:top_container] = { ref: @top_container_resource.id }
      end
    end
  end
end
