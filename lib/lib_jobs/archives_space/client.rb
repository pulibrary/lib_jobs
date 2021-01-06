# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class Client < ::ArchivesSpace::Client
      def self.build_config(**attributes)
        ::ArchivesSpace::Configuration.new(**attributes)
      end

      def self.parse_config(config_file_path)
        parsed = Configuration.new(config_file_path)
        build_config(parsed)
      end

      def self.build(config)
        new(config)
      end

      class Object
        def initialize(repository, **values)
          @repository = repository
          @values = OpenStruct.new(**values)
        end

        def to_h
          @values.to_h
        end

        def id
          @values[:id]
        end

        def update
          @repository.update_child(self)
        end

        def self.find(id:)
          @repository.find_child(resource_class: self, id: id)
        end
      end

      class TopContainer < Object
        def barcode
          return unless @values[:barcode]

          @barcode ||= AbsoluteId.find_or_initialize_by(value: @values[:barcode])
        end

        def barcode=(updated)
          @value[:barcode] = updated.value
        end
      end

      class SubContainer < Object
        def top_container
          @top_container_object ||= begin
                                      top_container_values = @values[:top_container]
                                      return unless top_container_values

                                      top_container_id = top_container_values[:ref]
                                      return unless top_container_id

                                      @repository.find_top_container(id: top_container_id)
                                    end
        end

        def top_container=(updated)
          # @values[:top_container] = updated.to_h
          @top_container_object = updated
          @values[:top_container] = { ref: @top_container_object.id }
        end
      end

      class Instance < Object
        def sub_container
          @sub_container ||= SubContainer.new(@values.sub_container)
        end

        def sub_container=(updated)
          @values[:sub_container] = updated.to_h
        end

        def top_container
          return unless sub_container

          sub_container.top_container
        end
      end

      class Resource < Object
        def instances
          @values[:instances].map { |instance| Instance.new(**instance) }
        end

        def instances=(updated)
          instance_values = updated.map(&:to_h)
          @values[:instances] = instance_values
        end

        def top_containers
          instances.map(&:top_container)
        end

        def barcodes
          top_containers.map(&:barcode)
        end

        def barcodes=(updated)
          bulk_values = top_containers.map do |top_container|
            {
              top_container.id => updated.barcode.value
            }
          end

          @repository.bulk_update_barcodes(bulk_values)
        end

        def update
          top_containers.each(&:update)
          super
        end
      end

      class Repository < Object
        def initialize(client:, id:)
          @client = client
          @id = id
        end

        def find_child(resource_class:, id:)
          response = @client.get("/repositories/#{@id}/#{resource_class.to_s.downcase.pluralize}/#{id}")
          return nil if response.status == 404

          resource_class.new(**response)
        end

        def find_resource(id:)
          # response = @client.get("/repositories/#{@id}/resources/#{id}")
          # return nil if response.status == 404

          # Resource.new(**response)
          find_child(resource_class: Resource, id: id)
        end

        def find_top_container(id:)
          # response = @client.get("/repositories/#{@id}/resources/#{id}")
          # return nil if response.status == 404

          # TopContainer.new(**response)
          find_child(resource_class: TopContainer, id: id)
        end

        def update_child(child)
          resource_class = child.class
          response = @client.post("/repositories/#{@id}/#{resource_class.to_s.downcase.pluralize}/#{child.id}", child.to_h)
          return nil if response.status == 400

          find_child(resource_class: child.class, id: child.id)
        end

        def update_top_container(top_container)
          # response = @client.post("/repositories/#{@id}/top_containers/#{top_container.id}", top_container.to_h)
          # return nil if response.status == 400

          # find_top_container(id: resource.id)
          update_child(top_container)
        end

        def update_resource(resource)
          # response = @client.post("/repositories/#{@id}/resources/#{resource.id}", resource.to_h)
          # return nil if response.status == 400

          # find_resource(id: resource.id)
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
end
