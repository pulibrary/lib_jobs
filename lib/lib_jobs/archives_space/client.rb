# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class Client < ::ArchivesSpace::Client
      def self.build_config(attributes)
        ::ArchivesSpace::Configuration.new(**attributes.to_h)
      end

      def self.build_from_file(config_file_path)
        config_file = File.open(config_file_path, 'rb')
        yaml_values = YAML.safe_load(config_file)

        parsed = Configuration.new(yaml_values)
        config = build_config(parsed)

        new(config)
      end

      def self.default_config_file_path
        Rails.root.join('config', 'archivesspace.yml')
      end

      def self.build
        build_from_file(default_config_file_path)
      end

      def repositories
        super.map do |repository_json|
          repository_attributes = repository_json.symbolize_keys.merge(client: self)
          Repository.new(repository_attributes)
        end
      end
    end
  end
end
