# frozen_string_literal: true

module LibJobs
  module ArchivesSpace
    class TopContainer < ChildObject
      attr_reader :active_restrictions,
                  :collection,
                  :exported_to_ils,
                  :ils_holding_id,
                  :ils_item_id,
                  :series,
                  :type

      def self.model_class
        AbsoluteId::TopContainer
      end

      def self.model_class_exists?
        true
      end

      def initialize(attributes)
        super(attributes)

        @resources = @values.resources || []

        @active_restrictions = @values.active_restrictions
        @collection = @values.collection
        @exported_to_ils = @values.exported_to_ils
        @ils_holding_id = @values.ils_holding_id
        @ils_item_id = @values.ils_item_id
        @series = @values.series
        @type = @values.type
      end

      def locations
        locations_values = @values.container_locations
        return [] if locations_values.nil?

        locations_values.map do |location_attributes|
          if location_attributes.key?(:ref)
            client.find_location_by(uri: location_attributes[:ref])
          elsif location_attributes.key?(:_resolved)
            LibJobs::ArchivesSpace::Location.new(location_attributes[:_resolved])
          else
            raise(ArgumentError, "Failed to construct a #{self.class} object from the arguments #{location_attributes.to_json}")
          end
        end
      end

      def attributes
        super.merge({
                      active_restrictions: active_restrictions,
                      barcode: barcode,
                      collection: collection,
                      container_locations: locations,
                      exported_to_ils: exported_to_ils,
                      ils_holding_id: ils_holding_id,
                      ils_item_id: ils_item_id,
                      indicator: indicator,
                      series: series,
                      resources: @resources,
                      type: type
                    })
      end

      def to_params
        {
          jsonmodel_type: "top_container",
          lock_version: lock_version,
          active_restrictions: active_restrictions,
          container_locations: container_locations_params,
          series: series,
          collection: collection,
          indicator: indicator,
          type: type,
          barcode: barcode,
          ils_holding_id: ils_holding_id,
          ils_item_id: ils_item_id,
          exported_to_ils: exported_to_ils
        }
      end

      def barcode
        @values.barcode
      end

      def indicator
        @values.indicator
      end

      def update(barcode: nil, indicator: nil, container_locations: [])
        @values.barcode = barcode if barcode
        @values.indicator = indicator if indicator

        @values.container_locations = container_locations.map(&:to_container_ref)

        repository.update_top_container(self)
      end

      private

      def container_locations_params
        @values.container_locations.map do |location|
          if location.is_a?(Location)
            location.to_container_ref
          else
            location
          end
        end
      end
    end
  end
end
