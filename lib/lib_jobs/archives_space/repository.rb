# frozen_string_literal: true

module LibJobs
  module ArchivesSpace
    class Repository < Object
      def self.model_class
        AbsoluteId::Repository
      end

      def build_top_container_from(documents:)
        container_doc = documents.first
        parsed = JSON.parse(container_doc['json'])

        response_body_json = parsed.transform_keys(&:to_sym)
        response_body_json[:repository] = self

        TopContainer.new(response_body_json)
      end

      attr_reader :name, :repo_code
      def initialize(attributes)
        super(attributes)

        @repo_code = attributes[:repo_code]
        @name = attributes[:name]
      end

      def attributes
        super.merge({
          name: name,
          repo_code: repo_code
        })
      end

      def children(resource_class:, model_class:)
        cached = model_class.all
        if !cached.empty?
          return cached.map(&:to_resource)
        end

        query = URI.encode_www_form([["page", "1"], ["page_size", "100000"]])
        response = client.get("/repositories/#{@id}/#{resource_class.name.demodulize.pluralize.underscore}?#{query}")
        return [] if response.status.code == "404"

        parsed = JSON.parse(response.body)
        results = parsed['results']
        results.map do |child_json|
          child_json = child_json.transform_keys(&:to_sym)
          child_json[:repository] = self

          resource = resource_class.new(child_json)
          model_class.cache(resource)
        end
      end

      def resource_model
        ::AbsoluteId::Resource
      end

      def archive_object_model
        ::AbsoluteId::ArchivalObject
      end

      def resources
        children(resource_class: Resource, model_class: resource_model)
      end

      def top_container_model
        ::AbsoluteId::TopContainer
      end

      def top_containers
        children(resource_class: TopContainer, model_class: top_container_model)
      end

      def search_top_containers(ead_id:, indicator:)
        resource_refs = client.find_resources_by_ead_id(repository_id: @id, ead_id: ead_id)
        resource = build_resource_from(refs: resource_refs)
        resource.search_top_containers(indicator: indicator)
      end

      def search_resources(ead_id:)
        resource_refs = find_resources_by_ead_id(ead_id: ead_id)
        resource = build_resource_from(refs: resource_refs)
      end

      def find_child(uri:, resource_class:, model_class:, resource: nil, cache: true)
        if cache
          cached = model_class.find_cached(uri.to_s)
          if !cached.nil?
            if !resource.nil?
              cached.resource = resource
            end
            cached.repository = self

            return cached
          end
        end

        response = client.get(uri.to_s)
        return nil if response.status.code != "200"

        parsed = JSON.parse(response.body)

        response_body_json = parsed.transform_keys(&:to_sym)
        response_body_json[:repository] = self
        response_body_json[:resource] = resource unless resource.nil?
        response_body_json[:uri] = uri.to_s

        resource = resource_class.new(response_body_json)
        if cache
          resource.cache
        end
        resource
      end

      # Deprecate
      def find_resource(uri:, resource: nil, cache: true)
        find_child(uri: uri, resource_class: Resource, model_class: Resource.model_class, cache: cache)
      end

      # Resource should be removed
      def find_resource_by(uri:, resource: nil, cache: true)
        find_child(uri: uri, resource_class: Resource, model_class: Resource.model_class, cache: cache)
      end

      def find_archival_object(resource:, uri:)
        find_child(uri: uri, resource_class: ArchivalObject, model_class: archive_object_model, resource: resource)
      end

      def find_resource_child_object(resource:, uri:)
        if uri.include?('archival_objects')
          find_archival_object(resource: resource, uri: uri)
        else
          find_resource(resource: resource, uri: uri)
        end
      end

      def build_resource_from(refs:, cache: true)
        resource_ref = refs.first

        resource_uri = "#{resource_ref['ref']}"
        find_resource_by(uri: resource_uri, cache: cache)
      end

      # Deprecate
      def find_top_container(uri:)
        find_child(uri: uri, resource_class: TopContainer, model_class: TopContainer.model_class)
      end
      def find_top_container_by(uri:)
        find_child(uri: uri, resource_class: TopContainer, model_class: TopContainer.model_class)
      end

      def select_top_containers_by(barcode:)
        output = top_containers.select do |top_container|
          top_container.barcode === barcode
        end
        output.to_a
      end

      def update_child(child:, model_class:)
        resource_class = child.class

        response = client.post("/repositories/#{@id}/#{resource_class.name.demodulize.pluralize.underscore}/#{child.id}", child.to_params)
        Rails.logger.warn(response.body)
        return nil if response.status.code != "200"

        model_class.uncache(child)

        find_child(uri: child.uri.to_s, resource_class: resource_class, model_class: model_class)
      end

      def update_top_container(top_container)
        update_child(child: top_container, model_class: top_container_model)
      end

      def update_resource(resource)
        update_child(child: resource, model_class: resource_model)
      end

      def bulk_update_barcodes(update_values)
        response = client.post("/repositories/#{@id}/top_containers/bulk/barcodes", update_values.to_h)
        return nil if response.status != 200 || !response[:id]

        find_resource(id: response[:id])
      end

      private

        def find_resources_by_ead_id(ead_id:)
          identifier_query = [ead_id]
          params = URI.encode_www_form([["identifier[]", identifier_query.to_json]])
          path = "/repositories/#{@id}/find_by_id/resources?#{params}"

          response = client.get(path)
          return [] unless response.parsed.key?('resources')

          response.parsed['resources']
        end
    end
  end
end
