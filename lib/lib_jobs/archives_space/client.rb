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
        client_config = ::ArchivesSpace::Configuration.new(config.to_h)
        super(client_config)
      end

      def base_uri
        return if @config.nil?

        @config.base_uri
      end

      # @param resource_class
      # @param model_class
      def children(resource_class:, model_class:)
        cached = model_class.cached
        if !cached.empty?
          return cached
        end

        query = URI.encode_www_form([["page", "1"], ["page_size", "100000"]])
        response = get("/#{resource_class.name.demodulize.pluralize.underscore}?#{query}")
        return [] if response.status.code == "404"

        parsed = JSON.parse(response.body)
        results = parsed['results']
        resources = results.map do |child_json|
          child_json = child_json.transform_keys(&:to_sym)
          child_json[:client] = self
          resource_class.new(child_json)
        end

        resources.map do |resource|
          model.cache(resource)
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

      # Move this into Repository
      def find_resources_by_ead_id(repository_id:, ead_id:)
        identifier_query = [ead_id]
        params = URI.encode_www_form([["identifier[]", identifier_query.to_json]])
        path = "/repositories/#{repository_id}/find_by_id/resources?#{params}"

        response = get(path)
        return [] unless response.parsed.key?('resources')

        response.parsed['resources']
      end

      # Move this into Repository
      def search_top_containers_by(repository_id:, query:)
        params = URI.encode_www_form([["q", query]])
        path = "/repositories/#{repository_id}/top_containers/search?#{params}"

        response = get(path)

        return [] unless response.parsed.key?('response')
        search_response = response.parsed['response']

        return [] unless search_response.key?('docs')
        search_response['docs']
      end

      def self.build_repository(repository_json)
        repository_attributes = repository_json.symbolize_keys.merge(client: self)
        Repository.new(repository_attributes)
      end

      # This is a different and distinct case from #children
      def repositories
        cached = repository_model.cached
        if !cached.empty?
          return cached
        end

        super.map do |repository_json|
          resource = self.class.build_repository(repository_json)
          repository_model.cache(resource)
        end
      end

      def repository_model
        ::AbsoluteId::Repository
      end

      def find_repository(id:)
        find_child(id: id, resource_class: Repository, model_class: repository_model)
      end

      def select_repositories_by(repo_code:)
        output = repositories.select do |repository|
          repository.repo_code === repo_code
        end
        output.to_a
      end

      # Container Profiles
      def select_container_profiles_by(name:)
        output = container_profiles.select do |container_profile|
          container_profile.name === name
        end
        output.to_a
      end

      def container_profile_model
        ::AbsoluteId::ContainerProfile
      end

      def container_profiles
        children(resource_class: ContainerProfile, model_class: container_profile_model)
      end

      # Locations
      def select_locations_by(classification:)
        output = locations.select do |location|
          location.classification === classification
        end
        output.to_a
      end

      def location_model
        ::AbsoluteId::Location
      end

      def locations
        children(resource_class: Location)
      end

      def find_child(id:, resource_class:, model_class:)
        cached = model_class.find_cached(id)
        if !cached.nil?
          return cached
        end

        response = get("/#{resource_class.name.demodulize.pluralize.underscore}/#{id}")
        raise StandardError, "Error requesting the #{resource_class.name.demodulize} #{id}: #{response.body}" if response.status.code != "200"

        parsed = JSON.parse(response.body)
        response_body_json = parsed.transform_keys(&:to_sym)
        resource_attributes = response_body_json.merge(client: self)

        resource = resource_class.new(resource_attributes)
        model_class.cache(resource)
      end

      def find_location(id:)
        find_child(id: id, resource_class: Location, model_class: location_model)
      end
    end
  end
end
