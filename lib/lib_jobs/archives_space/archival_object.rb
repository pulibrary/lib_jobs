# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class ArchivalObject < ResourceChildObject
      def self.model_class
        AbsoluteId::ArchivalObject
      end

      attr_reader :ref_id
      def initialize(attributes)
        super(attributes)

        @ref_id = @values.ref_id
      end

      def attributes
        super.merge({
          ref_id: ref_id
        })
      end
    end
  end
end
