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
        @base_uri ||= URI.build(protocol: protocol, host: host, port: port, path: path)
      end
    end
  end
end
