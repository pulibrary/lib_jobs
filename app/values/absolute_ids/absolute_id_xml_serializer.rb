# frozen_string_literal: true
module AbsoluteIds
  class AbsoluteIdXmlSerializer < RecordXmlSerializer

    def build_array_elements(element_name, enum_value)
      enum_element = document_tree.create_element(element_name)

      enum_value.each do |value|
        type_attribute = if value.is_a?(Hash)
                           'hash'
                         elsif value.is_a?(TrueClass) || value.is_a?(FalseClass)
                           'boolean'
                         elsif value.is_a?(NilClass)
                           nil
                         elsif value.is_a?(ActiveSupport::TimeWithZone)
                           'time'
                         else
                           value.class.to_s.underscore
                         end

        new_element = build_element(element_name: element_name, type_attribute: type_attribute, value: value)

        enum_element.add_child(new_element)
      end

      enum_element
    end

    def build_hash_element(element_name, hash_value)
      hash_element = document_tree.create_element(element_name)

      hash_value.each_pair do |key, value|
        child_element_name = key.to_s.underscore

        type_attribute = if value.is_a?(TrueClass) || value.is_a?(FalseClass)
                           'boolean'
                         elsif value.is_a?(NilClass)
                           nil
                         elsif value.is_a?(ActiveSupport::TimeWithZone)
                           'time'
                         else
                           value.class.to_s.underscore
                         end

        new_element = if type_attribute == 'hash'
                        build_hash_element(child_element_name, value)
                      else
                        build_element(element_name: child_element_name, type_attribute: type_attribute, value: value)
                      end
        if !new_element.nil?
          hash_element.add_child(new_element)
        end
      end

      hash_element
    end

    def build_element(element_name:, type_attribute:, value:)
      return if value.blank?

      if type_attribute == 'array'
        return build_array_elements(element_name, value)
      end

      if type_attribute == 'hash'
        return build_hash_element(element_name, value)
      end

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

      #new_element = build_element(element_name: 'barcode', type_attribute: 'string', value: @model.barcode.value)
      #root_element.add_child(new_element)

      @model.attributes.each_pair do |key, value|
        element_name = key.to_s.underscore

        type_attribute = if value.is_a?(Hash)
                           # build_hash_element(element_name, value)
                           'hash'
                         elsif value.is_a?(TrueClass) || value.is_a?(FalseClass)
#        type_attribute = if value.is_a?(TrueClass) || value.is_a?(FalseClass)
                           'boolean'
                         elsif value.is_a?(NilClass)
                           nil
                         elsif value.is_a?(ActiveSupport::TimeWithZone)
                           'time'
                         else
                           value.class.to_s.underscore
                         end
        new_element = build_element(element_name: element_name, type_attribute: type_attribute, value: value)

        if !new_element.nil?
          root_element.add_child(new_element)
        end
      end

      document_tree
    end
  end
end
