# frozen_string_literal: true

module LibJobs
  module ArchivesSpace
    class Repository < Object
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
        {
          id: id,
          uri: uri,
          repo_code: repo_code,
          name: name
        }
      end

      def children(resource_class:, model_class:)
        cached = model_class.all
        if !cached.empty?
          return cached
        end

        query = URI.encode_www_form([["page", "1"], ["page_size", "100000"]])
        response = @client.get("/repositories/#{@id}/#{resource_class.name.demodulize.pluralize.underscore}?#{query}")
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

      def resources
        children(resource_class: Resource, model_class: resource_model)
      end

      def top_container_model
        ::AbsoluteId::TopContainer
      end

      def top_containers
        children(resource_class: TopContainer, model_class: top_container_model)
      end

      def find_child(id:, resource_class:, model_class:)
        cached = model_class.find(id)
        if !cached.nil?
          return cached
        end

        response = @client.get("/repositories/#{@id}/#{resource_class.name.demodulize.pluralize.underscore}/#{id}")
        return nil if response.status == 404

        parsed = JSON.parse(response.body)

        response_body_json = parsed.transform_keys(&:to_sym)
        response_body_json[:repository] = self
        response_body_json[:id] = id
        resource = resource_class.new(response_body_json)
        model_class.cache(resource)
      end

      def find_resource(id:)
        find_child(id: id, resource_class: Resource, model_class: resource_model)
      end

      def build_resource_from(refs:)
        resource_ref = refs.first

        ref_path = resource_ref['ref']
        segments = ref_path.split('/')
        resource_id = segments.last

        find_resource(id: resource_id)
      end

      def find_top_container(id:)
        find_child(id: id, resource_class: TopContainer, model_class: top_container_model)
      end

      def select_top_containers_by(barcode:)
        output = top_containers.select do |top_container|
          top_container.barcode === barcode
        end
        output.to_a
      end

      def update_child(child:, model_class:)
        resource_class = child.class
        response = @client.post("/repositories/#{@id}/#{resource_class.name.demodulize.pluralize.underscore}/#{child.id}", child.to_params)
        return nil if response.status == 400

        model_class.uncache(child)

        find_child(resource_class: child.class, id: child.id)
      end

      def update_top_container(top_container)
        update_child(child: top_container, model_class: top_container_model)
      end

      def update_resource(resource)
        update_child(child: resource, model_class: resource_model)
      end

      def bulk_update_barcodes(update_values)
        response = @client.post("/repositories/#{@id}/top_containers/bulk/barcodes", update_values.to_h)
        return nil if response.status != 200 || !response[:id]

        find_resource(id: response[:id])
      end
    end
  end
end
