# frozen_string_literal: true

module LibJobs
  module ArchivesSpace
    class ContainerProfile < Object
      attr_accessor :prefix
      attr_reader :name
      def initialize(attributes)
        super(attributes)

        @name = attributes[:name]
        @prefix = attributes[:prefix]
      end

      def attributes
        super.merge({
                      name: name,
                      prefix: prefix
                    })
      end
    end
  end
end
