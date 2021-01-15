
# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class Object
      attr_reader :id

      def initialize(attributes)
        normalized = attributes.deep_symbolize_keys

        @repository = normalized.fetch(:repository)
        @values = OpenStruct.new(normalized)
      end

      def attributes
        @values.to_h
      end

      def to_h
        attributes
      end

      def as_json(**_options)
        attributes
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
