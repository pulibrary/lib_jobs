module LibJobs
  module ArchivesSpace
    class ChildObject < Object
      def initialize(attributes)
        super(attributes)

        @repository = @values.repository
        @repository_uri = @values.repository_uri
      end

      def repository
        @repository ||= begin
                          return unless client
                          client.find_repository_by(uri: repository_uri)
                        end
      end

      def client
        return if repository.nil?

        repository.client
      end

      def update
        return if repository.nil?

        repository.update_child(self)
      end
    end
  end
end
