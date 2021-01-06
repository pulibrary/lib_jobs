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

      class BaseResource
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

        def self.find(id:)
          NotImplementedError
        end
      end

      class TopContainer < BaseResource
        def ref
          @values[:ref]
        end

        def barcode
          @values[:barcode]
        end

        def barcode=(updated)
          @value[:barcode] = updated
        end

        def self.find(id:)
          @repository.find_top_container(id)
        end

        def update
          @repository.update_top_container(id, @values)
        end
      end

      class SubContainer < BaseResource
        def top_container
          TopContainer.new(@values.top_container)
        end

        def top_container=(updated)
          @values[:top_container] = updated.to_h
        end
      end

      class Instance < BaseResource
        def sub_container
          SubContainer.new(@values.sub_container)
        end

        def sub_container=(updated)
          @values[:sub_container] = updated.to_h
        end
      end

      class Resource < BaseResource
        def instances
          @values[:instances].map { |instance| Instance.new(**instance) }
        end

        def instances=(updated)
          instance_values = updated.map(&:to_h)
          @values[:instances] = instance_values
        end
      end

      class Repository
        def initialize(client:, id:)
          @client = client
          @id = id
        end

        def find_resource(id:)
          response = @client.get("/repositories/#{@id}/resources/#{id}")
          return nil if response.status == 404

          Resource.new(**response)
        end

        def update_resource(resource:)
          response = @client.post("/repositories/#{@id}/resources/#{id}", resource)
          return nil if response.status == 400

          find_resource(id: resource.id)
        end
      end
      end
  end
end
