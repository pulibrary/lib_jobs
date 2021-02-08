# frozen_string_literal: true

module LibJobs
  module ArchivesSpace
    class Repository < Object
      def self.parse_id(attributes)
        uri = attributes[:uri]
        segments = uri.split("/")
        segments.last
      end

      attr_reader :client, :uri
      def initialize(attributes)
        @values = OpenStruct.new(attributes)

        @client = attributes[:client]

        @repo_code = attributes[:repo_code]
        @name = attributes[:name]

        @id = attributes[:id] || self.class.parse_id(attributes)
        @uri = generate_uri
      end

      def repository
        self
      end

      def generate_uri
        URI.join(@client.config.base_uri, @values.uri)
      end

      def attributes
        {
          id: @id,
          uri: @uri,
          repo_code: @repo_code,
          name: @name
        }
      end

      def children(resource_class:)
        query = URI.encode_www_form([["page", "1"], ["page_size", "100000"]])
        response = @client.get("/repositories/#{@id}/#{resource_class.name.demodulize.pluralize.underscore}?#{query}")
        return [] if response.status.code == "404"

        parsed = JSON.parse(response.body)
        results = parsed['results']
        results.map do |child_json|
          child_json = child_json.transform_keys(&:to_sym)
          child_json[:repository] = self
          resource_class.new(child_json)
        end
      end

      def resources
        children(resource_class: Resource)
      end

      def top_containers
        children(resource_class: TopContainer)
      end

      def find_child(resource_class:, id:)
        response = @client.get("/repositories/#{@id}/#{resource_class.name.demodulize.pluralize.underscore}/#{id}")
        return nil if response.status == 404

        parsed = JSON.parse(response.body)

        response_body_json = parsed.transform_keys(&:to_sym)
        response_body_json[:repository] = self
        response_body_json[:id] = id
        resource_class.new(@client, **response_body_json)
      end

      def find_resource(id:)
        find_child(resource_class: Resource, id: id)
      end

      def find_top_container(id:)
        find_child(resource_class: TopContainer, id: id)
      end

      def update_child(child)
        resource_class = child.class
        response = @client.post("/repositories/#{@id}/#{resource_class.name.demodulize.pluralize.underscore}/#{child.id}", child.api_params)
        return nil if response.status == 400

        find_child(resource_class: child.class, id: child.id)
      end

      def update_top_container(top_container)
        update_child(top_container)
      end

      def update_resource(resource)
        update_child(resource)
      end

      def bulk_update_barcodes(update_values)
        response = @client.post("/repositories/#{@id}/top_containers/bulk/barcodes", update_values.to_h)
        return nil if response.status != 200 || !response[:id]

        find_resource(id: response[:id])
      end
    end
  end
end
