# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class Client < ::ArchivesSpace::Client
      def self.build_config(attributes)
        ::ArchivesSpace::Configuration.new(**attributes.to_h)
      end

      def self.parse_config(config_file_path)
        config_file = File.open(config_file_path, 'rb')
        yaml_values = YAML.safe_load(config_file)

        parsed = Configuration.new(yaml_values)
        config = build_config(parsed)

        new(config)
      end
    end
  end
end
