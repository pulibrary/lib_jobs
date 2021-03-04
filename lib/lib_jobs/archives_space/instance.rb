# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class Instance < Object

      # These are nested objects
      def initialize(attributes)
        normalized = attributes.deep_symbolize_keys
        @values = OpenStruct.new(normalized)

        # @client = @values.client
        # ["lock_version", "created_by", "last_modified_by", "create_time", "system_mtime", "user_mtime", "instance_type", "jsonmodel_type", "is_representative", "sub_container"]
        @repository = @values.repository

        @create_time = @values.create_time
        @system_mtime = @values.system_mtime
        @user_mtime = @values.user_mtime
        @lock_version = @values.lock_version
      end

      def sub_container
        @sub_container ||= SubContainer.new(@values.sub_container.merge(repository: @repository))
      end

      def sub_container=(updated)
        @values[:sub_container] = updated.to_h
      end

      def top_container
        return unless sub_container

        sub_container.top_container
      end
    end
  end
end
