# frozen_string_literal: true
module AbsoluteIds
  class BarcodeXmlSerializer < RecordXmlSerializer
    def build_element(element_name:, type_attribute:, value:)
      new_element = document_tree.create_element(element_name)
      new_element['type'] = type_attribute unless type_attribute.nil?

      if value.respond_to?(:each)
        children = value.map { |child_value| build_element(element_name: element_name, type_attribute: type_attribute, value: child_value) }
        node_set = Nokogiri::XML::NodeSet.new(document_tree, children)
        new_element.children = node_set
      else
        new_element.content = value
      end

      new_element
    end

    def build_document
      @document_tree = build_document_tree

      @model.attributes.each_pair do |key, value|
        element_name = key.to_s.underscore
        type_attribute = if value.is_a?(TrueClass) || value.is_a?(FalseClass)
                           'boolean'
                         elsif value.is_a?(NilClass)
                           nil
                         elsif value.is_a?(ActiveSupport::TimeWithZone)
                           'time'
                         else
                           value.class.to_s.underscore
                         end
        new_element = build_element(element_name: element_name, type_attribute: type_attribute, value: value)

        root_element.add_child(new_element)
      end

      document_tree
    end
  end
end
