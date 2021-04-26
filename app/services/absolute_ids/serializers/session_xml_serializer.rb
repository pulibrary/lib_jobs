# frozen_string_literal: true
module AbsoluteIds
  module Serializers
    class SessionXmlSerializer < RecordXmlSerializer
      private

      def build_document
        @document_tree = build_document_tree

        @model.batches.each do |batch|
          new_element_xml = batch.to_xml
          new_element_doc = Nokogiri::XML(new_element_xml)

          root_element.add_child(new_element_doc.root)
        end

        document_tree
      end
    end
  end
end
