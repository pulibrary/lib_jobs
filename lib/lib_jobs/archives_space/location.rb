# frozen_string_literal: true

module LibJobs
  module ArchivesSpace
    class Location < Object
      attr_reader :area,
                  :barcode,
                  :building,
                  :classification,
                  :external_ids,
                  :floor,
                  :functions,
                  :id,
                  :room,
                  :temporary,
                  :uri

      def initialize(attributes)
        super(attributes)

        @area = attributes[:area]
        @barcode = attributes[:building]
        @building = attributes[:building]
        @classification = attributes[:classification]
        @external_ids = attributes[:external_ids]
        @floor = attributes[:floor]
        @functions = attributes[:functions]
        @room = attributes[:room]
        @temporary = attributes[:temporary]
      end

      def attributes
        {
          area: area,
          barcode: barcode,
          building: building,
          classification: classification,
          external_ids: external_ids,
          floor: floor,
          functions: functions,
          id: id,
          room: room,
          temporary: temporary,
          uri: uri
        }
      end

      def to_container_ref
        {
          jsonmodel_type: 'container_location',
          status: 'current',
          start_date: start_date,
          system_mtime: @values.system_mtime,
          user_mtime: @values.user_mtime,
          ref: ref
        }
      end

      private

      def ref
        segments = uri.to_s.split('/')
        subset = segments[(-2..-1)]
        output = subset.join('/')
        "/#{output}"
      end

      def start_date
        create_time = @values.create_time
        segments = create_time.split('T')
        segments.first
      end
    end
  end
end
