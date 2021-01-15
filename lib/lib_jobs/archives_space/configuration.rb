# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class Configuration < OpenStruct
      def self.parse_erb(yaml_file_path)
        io_stream = IO.read(yaml_file_path)
        erb_document = ERB.new(io_stream)
        erb_document.result(binding)
      end

      def self.parse(yaml_file_path)
        config_erb = parse_erb(yaml_file_path)
        parsed = YAML.safe_load(config_erb)
        new(**parsed.symbolize_keys)
      rescue StandardError, SyntaxError => e
        raise("#{yaml_file_path} was found, but could not be parsed: \n#{e.inspect}")
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
