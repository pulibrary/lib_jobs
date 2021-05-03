# frozen_string_literal: true

module LibJobs
  module ArchivesSpace
    class Repository < Object
      def self.configuration
        LibJobs.config[:repositories]
      end

      def self.model_class
        AbsoluteId::Repository
      end

      def self.model_class_exists?
        true
      end

      def self.find_classification_by(repo_code:)
        configuration[repo_code]
      end

      attr_reader :name, :repo_code
      def initialize(attributes)
        super(attributes)

        @repo_code = attributes[:repo_code]
        @name = attributes[:name]
      end

      def classification
        self.class.find_classification_by(repo_code: repo_code)
      end

      def attributes
        super.merge({
                      name: name,
                      repo_code: repo_code
                    })
      end

      # Construct a TopContainer object from a SolrDocument
      # @param document
      # @return TopContainer
      def build_top_container_from(document:)
        parsed = JSON.parse(document['json'])

        response_body_json = parsed.transform_keys(&:to_sym)
        response_body_json[:repository] = self

        TopContainer.new(response_body_json)
      end

      def resources
        children(resource_class: Resource, model_class: Resource.model_class)
      end

      def top_containers
        children(resource_class: TopContainer, model_class: TopContainer.model_class)
      end

      # Search for TopContainers
      # @param barcode
      # @param indicator
      # @param collection
      # @param resource_class
      # @return [Array<TopContainer>]
      def search_top_containers_by(barcode: nil, indicator: nil, resource_class: TopContainer)
        query_params = []
        query_params << ["q", indicator] unless indicator.nil?
        query_params << ["q", barcode] unless barcode.nil?

        query = URI.encode_www_form(query_params)
        response = client.get("/repositories/#{@id}/#{resource_class.name.demodulize.pluralize.underscore}/search?#{query}")

        return [] if response.status.code == "404"

        parsed = JSON.parse(response.body)
        return [] unless parsed.key?('response') || parsed['response'].key?('docs')

        solr_response = parsed['response']
        return [] unless solr_response.key?('docs')

        solr_documents = solr_response['docs']
        solr_documents.map do |document|
          build_top_container_from(document: document)
        end
      end

      # Search for TopContainers
      # @param barcode
      # @param indicator
      # @param collection
      # @param resource_class
      # @return [Array<TopContainer>]
      def search_top_container_children_by(collection: nil)
        query_params = []
        query_params << ["q", "collection_identifier_u_stext:#{collection}"] unless collection.nil?

        query_params << ["type[]", "top_container"]
        query_params << ["page", "1"]

        query = URI.encode_www_form(query_params)
        response = client.get("/repositories/#{@id}/search?#{query}")

        return [] if response.status.code == "404"

        parsed = JSON.parse(response.body)
        return [] unless parsed.key?('results')

        solr_documents = parsed['results']
        solr_documents.map do |document|
          build_top_container_from(document: document)
        end
      end

      # Deprecate
      def find_resource(uri:, cache: true)
        find_child(uri: uri, resource_class: Resource, model_class: Resource.model_class, cache: cache)
      end

      def find_resource_by(uri: nil, id: nil, parent: nil, cache: true)
        find_child_by(resource_class: Resource, model_class: Resource.model_class, uri: uri, child_id: id, parent: parent, cache: cache)
      end

      # This does not have a caching option
      def find_archival_object_by(resource:, uri:)
        find_child_by(resource_class: ArchivalObject, model_class: ArchivalObject.model_class, uri: uri, parent: resource)
      end

      def build_resource_from(refs:, cache: true)
        resource_ref = refs.first

        resource_uri = (resource_ref['ref']).to_s
        find_resource_by(uri: resource_uri, cache: cache)
      end

      def find_top_container_by(uri:)
        find_child(uri: uri, resource_class: TopContainer, model_class: TopContainer.model_class)
      end

      def select_top_containers_by(barcode:)
        output = top_containers.select do |top_container|
          top_container.barcode == barcode
        end
        output.to_a
      end

      def update_top_container(top_container)
        update_child(child: top_container, model_class: TopContainer.model_class)
      end

      def update_resource(resource)
        update_child(child: resource, model_class: Resource.model_class)
      end

      def bulk_update_barcodes(update_values)
        response = client.post("/repositories/#{@id}/top_containers/bulk/barcodes", update_values.to_h)
        return nil if response.status != 200 || !response[:id]

        find_resource(id: response[:id])
      end

      def batch_update_top_containers(containers:, container_profile_uri: nil, location_uri: nil)
        request_path_base = "/repositories/#{@id}/top_containers/batch"
        jsonmodel_type = if !container_profile_uri.nil?
                           "container_profile"
                         else
                           "location"
                         end

        request_params = {
          'ids[]': containers.map(&:id)
        }

        request_params[:container_profile_uri] = container_profile_uri unless container_profile_uri.nil?

        request_params[:location_uri] = location_uri unless location_uri.nil?

        query_params = URI.encode_www_form(request_params)
        request_path = "#{request_path_base}/#{jsonmodel_type}?#{query_params}"
        response = client.post(request_path, {})

        if response.status.code == "400"
          error_message = response.parsed.values.map(&:values).join('. ')
          raise(BatchUpdateRecordError, error_message)
        elsif response.status.code != "200"
          []
        end

        containers.map do |container|
          container.class.model_class.uncache(container)

          find_child(uri: container.uri.to_s, resource_class: container.class, model_class: container.class.model_class)
        end
      end

      def update_child(child:, model_class:)
        resource_class = child.class

        child_uri = "/repositories/#{@id}/#{resource_class.name.demodulize.pluralize.underscore}/#{child.id}"
        response = client.post(child_uri, child.to_params)

        if response.status.code == "404"
          error_message = "Resource not found for #{child_uri}"
          raise(UpdateRecordError, error_message)
        elsif response.status.code != "200"
          error_message = response.parsed.values.map(&:values).join('. ')
          raise(UpdateRecordError, error_message)
        end

        model_class.uncache(child)

        find_child(uri: child.uri.to_s, resource_class: resource_class, model_class: model_class)
      end

      private

      def children(resource_class:, model_class:)
        cached = model_class.all
        return cached.map(&:to_resource) unless cached.empty?

        query_params = [["page", "1"], ["page_size", "100000"]]
        query_params += [["resolve[]", "container_locations"]] if model_class == AbsoluteId::TopContainer
        query = URI.encode_www_form(query_params)
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

      def find_child(uri:, resource_class:, model_class:, parent: nil, cache: true)
        if cache
          cached = model_class.find_cached(uri.to_s)
          unless cached.nil?
            cached.resource = parent unless parent.nil?
            cached.repository = self

            return cached
          end
        end

        response = client.get(uri.to_s)
        return nil if response.status.code != "200"

        parsed = JSON.parse(response.body)

        response_body_json = parsed.transform_keys(&:to_sym)
        response_body_json[:repository] = self
        response_body_json[:resource] = parent unless parent.nil?
        response_body_json[:uri] = uri.to_s

        built = resource_class.new(response_body_json)
        built.cache if cache
        built
      end

      # rubocop:disable Metrics/ParameterLists
      def find_child_by(resource_class:, model_class:, parent: nil, uri: nil, child_id: nil, cache: true)
        uri = "/repositories/#{@id}/#{resource_class.name.demodulize.pluralize.underscore}/#{child_id}" if uri.nil? && !child_id.nil?

        find_child(uri: uri.to_s, resource_class: resource_class, model_class: model_class, parent: parent, cache: cache)
      end
      # rubocop:enable Metrics/ParameterLists

      def find_resource_child_object_by(resource:, uri:)
        if uri.include?('archival_objects')
          find_archival_object(resource: resource, uri: uri)
        else
          find_resource(resource: resource, uri: uri)
        end
      end
    end
  end
end
