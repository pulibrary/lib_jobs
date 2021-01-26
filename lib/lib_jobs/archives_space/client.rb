# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class Client < ::ArchivesSpace::Client
      def self.default_config_file_path
        Rails.root.join('config', 'archivesspace.yml')
      end

      def self.default_config
        config = Configuration.parse(default_config_file_path)
      end

      def self.default
        new(default_config)
      end

      def initialize(config)
        client_config = ::ArchivesSpace::Configuration.new(config.to_h)
        super(client_config)
      end

      def base_uri
        return if @config.nil?

        @config.base_uri
      end

      # This needs to be deduplicated
      def children(resource_class:)
        query = URI.encode_www_form([["page", "1"], ["page_size", "100000"]])
        response = get("/#{resource_class.name.demodulize.pluralize.underscore}?#{query}")
        return [] if response.status.code == "404"

        parsed = JSON.parse(response.body)
        results = parsed['results']
        results.map do |child_json|
          child_json = child_json.transform_keys(&:to_sym)
          child_json[:client] = self
          resource_class.new(child_json)
        end
      end

      def locations
        children(resource_class: Location)
      end

      def container_profiles
        super.map do |repository_json|
          repository_attributes = repository_json.symbolize_keys.merge(client: self)
          ContainerProfile.new(repository_attributes)
        end
      end

      def repositories
        super.map do |repository_json|
          repository_attributes = repository_json.symbolize_keys.merge(client: self)
          Repository.new(repository_attributes)
        end
      end

      def find_repository(id:)
        response = get("/repositories/#{id}")
        raise StandardError, "Error requesting the repository #{id}: #{response.body}" if response.status.code != "200"

        parsed = JSON.parse(response.body)
        response_body_json = parsed.transform_keys(&:to_sym)
        repository_attributes = response_body_json.merge(client: self)

        Repository.new(repository_attributes)
      end
    end
  end
end
