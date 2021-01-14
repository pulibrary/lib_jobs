# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class Configuration < OpenStruct
      def self.parse(yaml_file_path)
        yaml_file = File.read(yaml_file_path, 'rb')
        parsed = YAML.safe_load(yaml_file)
        new(**parsed)
      end

      def base_uri
        @base_uri ||= URI::Generic.build(scheme: protocol, host: host, port: port, path: path)
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
