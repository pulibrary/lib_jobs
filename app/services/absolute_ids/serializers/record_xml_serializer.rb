# frozen_string_literal: true
module AbsoluteIds
  module Serializers
    class RecordXmlSerializer
      def initialize(model, _options = {})
        @model = model
      end

      def serialize
        document.to_xml
      end

      private

      def model_element_name
        "<#{@model.model_name.to_s.demodulize.underscore} />"
      end

      def build_document_tree
        Nokogiri::XML(model_element_name)
      end

      def document_tree
        @document_tree ||= build_document_tree
      end

      def root_element
        @root_element ||= document_tree.root
      end

      def document
        @document ||= build_document
      end
    end
  end
end
