# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class Resource < ResourceChildObject
      def self.model_class
        AbsoluteId::Resource
      end

      def self.model_class_exists?
        true
      end

      attr_reader :ead_id
      def initialize(attributes)
        super(attributes)

        @ead_id = @values.ead_id
      end

      def attributes
        super.merge({
                      ead_id: ead_id
                    })
      end

      def search_top_containers_by(index:, cache: true)
        resolved = if !cache || top_containers.empty?
                     resolve_top_containers
                   else
                     top_containers
                   end

        sorted = resolved.sort_by(&:id)
        found = sorted[index.to_i - 1]

        raise(IndexError, "Failed to find the TopContainer using #{index}") if found.nil?
        [found]
      end

      def barcodes
        top_containers.map(&:barcode)
      end

      def barcodes=(updated)
        bulk_values = top_containers.zip(updated).map do |values|
          top_container = values.first
          updated = values.last

          {
            top_container.id => updated.to_s
          }
        end

        repository.bulk_update_barcodes(bulk_values)
        @top_containers = nil
      end

      def update
        top_containers.each(&:update)
        super
      end
    end
  end
end
