# frozen_string_literal: true

module LibJobs
  module ArchivesSpace
    class TopContainer < Object
      # def barcode
      #  return unless @values[:barcode]

      #  @barcode ||= AbsoluteId.find_or_initialize_by(value: @values[:barcode])
      # end

      # def barcode=(updated)
      #  @value[:barcode] = updated.value
      # end

      def self.parse_id(attributes)
        uri = attributes[:uri]
        segments = uri.split("/")
        segments.last
      end

      def generate_uri
        path = @values.uri
        URI.join(@repository.uri, path)
      end

      def initialize(client, attributes)
        super(attributes)

        @id = self.class.parse_id(attributes)
        @uri = generate_uri
      end

      def barcode
        @values.barcode
      end

      def indicator
        @values.indicator
      end

      def locations
        @locations ||= begin
                         locations_values = @values.container_locations
                         locations_values.map do |location_attributes|
                           #location_attributes[:uri] = location_attributes[:ref]

                           segments = location_attributes[:ref].split('/')
                           location_id = segments.last

                           #Location.new(location_attributes)
                           client.find_location(id: location_id)
                         end
                       end
      end

      def attributes
        {
          id: @id,
          uri: @uri,
          barcode: barcode,
          indicator: indicator,
          container_locations: locations
        }
      end

      def container_locations_api_params
        @values.container_locations.map do |location|
          if location.is_a?(Location)
            location.to_container_ref
          else
            location
          end
        end
      end

      def api_params
        {
          jsonmodel_type: "top_container",
          lock_version: @values.lock_version,
          active_restrictions: @values.active_restrictions,
          container_locations: container_locations_api_params,
          series: @values.series,
          collection: @values.collection,
          indicator: indicator,
          type: @values.type,
          barcode: barcode,
          ils_holding_id: @values.ils_holding_id,
          ils_item_id: @values.ils_item_id,
          exported_to_ils: @values.exported_to_ils
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
    end
  end
end
