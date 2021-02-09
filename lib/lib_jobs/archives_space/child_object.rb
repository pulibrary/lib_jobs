module LibJobs
  module ArchivesSpace
    class ChildObject < Object
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
        return if repository.nil?

        repository.update_child(self)
      end
    end
  end
end
