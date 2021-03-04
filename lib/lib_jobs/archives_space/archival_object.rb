# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class ArchivalObject < ResourceChildObject
      attr_reader :ref_id, :title, :level
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
