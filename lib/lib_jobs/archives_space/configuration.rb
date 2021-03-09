# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class Configuration < OpenStruct
      def self.build
        @build ||= begin
                     parsed = LibJobs.config["archivesspace"]
                     new(**parsed.symbolize_keys)
                   end
      end

      def self.source
        build.source
      end

      def self.sync
        build.sync
      end

      def generate_base_uri
        URI::Generic.build(scheme: protocol, host: host, port: port, path: path)
      end

      def base_uri
        @base_uri ||= super || generate_base_uri
      end

      def attributes
        {
          base_uri: base_uri.to_s
        }
      end

      def to_h
        super.merge(attributes)
      end
    end
  end
end
