# frozen_string_literal: true

module LibJobs
  module ArchivesSpace
    class TopContainer < ChildObject
      attr_reader :active_restrictions,
                  :barcode,
                  :collection,
                  :exported_to_ils,
                  :ils_holding_id,
                  :ils_item_id,
                  :indicator,
                  :series,
                  :type

      def self.model_class
        AbsoluteId::TopContainer
      end

      def initialize(attributes)
        super(attributes)

        @active_restrictions = @values.active_restrictions
        @barcode = @values.barcode
        @collection = @values.collection
        @exported_to_ils = @values.exported_to_ils
        @ils_holding_id = @values.ils_holding_id
        @ils_item_id = @values.ils_item_id
        @indicator = @values.indicator
        @series = @values.series
        @type = @values.type
      end

      def locations
        @locations ||= begin
                         locations_values = @values.container_locations
                         return [] if locations_values.nil?

                         locations_values.map do |location_attributes|
                           # location_uri = "#{base_uri}#{location_attributes[:ref]}"
                           location_uri = "#{location_attributes[:ref]}"
                           client.find_location(uri: location_uri)
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

      def update(barcode: nil, indicator: nil, container_locations: [])
        @values.barcode = barcode if barcode
        @values.indicator = indicator if indicator

        @values.container_locations = container_locations.map do |location|
          location.to_container_ref
        end

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
