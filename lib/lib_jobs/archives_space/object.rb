
# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class Object
      def initialize(repository, attributes)
        @repository = repository
        @values = OpenStruct.new(attributes.deep_symbolize_keys)
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
  end
end
