# frozen_string_literal: true
module AbsoluteIds
  module Serializers
    class BatchXmlSerializer < RecordXmlSerializer
      private

      def build_document
        @document_tree = build_document_tree

        @model.absolute_ids.each do |absolute_id|
          new_element_xml = absolute_id.to_xml
          new_element_doc = Nokogiri::XML(new_element_xml)

          root_element.add_child(new_element_doc.root)
        end

        document_tree
      end
    end
  end
end
