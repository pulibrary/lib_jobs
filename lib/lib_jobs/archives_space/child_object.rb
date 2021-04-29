# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class ChildObject < Object
      attr_writer :repository
      def initialize(attributes)
        super(attributes)

        @repository = @values.repository
        @repository_uri = @values.repository_uri
        @repository_id = @values.repository_id
      end

      def repository
        @repository ||= begin
                          return unless client

                          if @repository_id
                            client.find_repository_by(id: @repository_id)
                          else
                            client.find_repository_by(uri: @repository_uri)
                          end
                        end
      end

      def update
        return if repository.nil?

        repository.update_child(child: self, model_class: self.class)
      end
    end
  end
end
