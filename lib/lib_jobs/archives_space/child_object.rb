module LibJobs
  module ArchivesSpace
    class ChildObject < Object
      def self.find(id:)
        @repository.find_child(resource_class: self, id: id)
      end

      attr_reader :repository
      def initialize(attributes)
        super(attributes)
        @repository = @values.repository
      end

      def client
        return if repository.nil?

        repository.client
      end

      def update
        repository.update_child(self)
      end
    end
  end
end
