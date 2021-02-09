# frozen_string_literal: true

module LibJobs
  module ArchivesSpace
    class ContainerProfile < Object
      attr_accessor :prefix
      attr_reader :name

      def attributes
        {
          id: @id,
          uri: @uri,
          name: @name,
          prefix: prefix
        }
      end
    end
  end
end
