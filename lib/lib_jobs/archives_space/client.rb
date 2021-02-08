# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class Client < ::ArchivesSpace::Client
      #def self.source_config_file_path
      #  Rails.root.join('config', 'archives_space', 'source.yml')
      #end

      #def self.sync_config_file_path
      #  Rails.root.join('config', 'archives_space', 'sync.yml')
      #end

      def self.source
        new(Configuration.source)
      end

      def self.sync
        new(Configuration.sync)
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

      def search_results(response:, resource_class:)
        parsed = JSON.parse(response.body)
        results = parsed['results']
        results.map do |child_json|
          child_json = child_json.transform_keys(&:to_sym)
          child_json[:client] = self
          resource_class.new(child_json)
        end
      end

      def find_resources_by_ead_id(repository_id:, ead_id:)
        identifier_query = [ead_id]
        params = URI.encode_www_form([["identifier[]", identifier_query.to_json]])
        path = "/repositories/#{repository_id}/find_by_id/resources?#{params}"

        response = get(path)
        return [] unless response.parsed.key?('resources')

        response.parsed['resources']
      end

      def search_top_containers_by(repository_id:, query:)
        params = URI.encode_www_form([["q", query]])
        path = "/repositories/#{repository_id}/top_containers/search?#{params}"

        response = get(path)

        return [] unless response.parsed.key?('response')
        search_response = response.parsed['response']

        return [] unless search_response.key?('docs')
        search_response['docs']
      end

      def locations
        children(resource_class: Location)
      end

      def container_profiles
        children(resource_class: ContainerProfile)
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

      def select_repositories_by(repo_code:)
        output = repositories.select do |repository|
          repository.repo_code === repo_code
        end
        output.to_a
      end

      def select_container_profiles_by(name:)
        output = container_profiles.select do |container_profile|
          container_profile.name === name
        end
        output.to_a
      end

      def select_locations_by(classification:)
        output = locations.select do |location|
          location.classification === classification
        end
        output.to_a
      end

      def find_location(id:)
        response = get("/locations/#{id}")
        raise StandardError, "Error requesting the location #{id}: #{response.body}" if response.status.code != "200"

        parsed = JSON.parse(response.body)
        response_body_json = parsed.transform_keys(&:to_sym)
        location_attributes = response_body_json.merge(client: self)

        Location.new(location_attributes)
      end
    end
  end
end
