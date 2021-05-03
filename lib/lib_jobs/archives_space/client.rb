# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class Client < ::ArchivesSpace::Client
      def self.source
        new(Configuration.source)
      end

      def self.sync
        new(Configuration.sync)
      end

      def initialize(config)
        client_config = ::ArchivesSpace::Configuration.new(config.to_h.symbolize_keys)
        super(client_config)
      end

      def base_uri
        return if @config.nil?

        @config.base_uri
      end

      # Move this into Repository
      def find_resources_by_ead_id(repository_id:, ead_id:)
        identifier_query = [ead_id]
        params = URI.encode_www_form([["identifier[]", identifier_query.to_json]])
        path = "/repositories/#{repository_id}/find_by_id/resources?#{params}"

        response = get(path)
        return [] unless response.parsed.key?('resources')

        response.parsed['resources']
      end

      def build_repository(repository_json)
        repository_attributes = repository_json.symbolize_keys.merge(client: self)
        Repository.new(repository_attributes)
      end

      # This is a different and distinct case from #children
      def repositories
        super.to_a.map do |repository_json|
          build_repository(repository_json)
        end
      end

      # Deprecate this
      def find_repository(uri: nil, id: nil)
        find_child_by(uri: uri, resource_class: Repository, model_class: Repository.model_class, child_id: id)
      end

      def find_repository_by(uri: nil, id: nil)
        find_child_by(uri: uri, resource_class: Repository, model_class: Repository.model_class, child_id: id)
      end

      def select_repositories_by(repo_code: nil, classification: nil)
        output = repositories.select do |repository|
          repository.classification
          if !classification.nil?
            repository.classification == classification
          elsif !repo_code.nil?
            repository.repo_code == repo_code
          else
            false
          end
        end

        output.to_a
      end

      # Container Profiles
      def select_container_profiles_by(name:)
        output = container_profiles.select do |container_profile|
          container_profile.name == name
        end
        output.to_a
      end

      def container_profiles
        children(resource_class: ContainerProfile)
      end

      # Locations
      def select_locations_by(classification:)
        output = locations.select do |location|
          location.classification == classification
        end
        output.to_a
      end

      def locations
        children(resource_class: Location)
      end

      def find_location_by(uri:)
        find_child_by(uri: uri, resource_class: Location)
      end

      private

      def find_child(uri:, resource_class:, model_class: nil)
        model_class ||= resource_class.model_class unless resource_class.nil? || !resource_class.model_class_exists?
        unless model_class.nil?
          cached = model_class.find_cached(uri, self)
          return cached unless cached.nil?
        end

        response = get(uri)
        raise(StandardError, "Error requesting the #{resource_class.name.demodulize} #{uri}: #{response.body}") if response.status.code != "200"

        parsed = JSON.parse(response.body)
        response_body_json = parsed.transform_keys(&:to_sym)
        resource_attributes = response_body_json.merge(client: self)

        built = resource_class.new(resource_attributes)
        model_class&.cache(built) || built
      end

      def find_child_by(resource_class:, model_class: nil, uri: nil, child_id: nil)
        uri = "/#{resource_class.name.demodulize.pluralize.underscore}/#{child_id}" if uri.nil? && !child_id.nil?

        find_child(uri: uri.to_s, resource_class: resource_class, model_class: model_class)
      end

      # @param resource_class
      # @param model_class
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
    end
  end
end
