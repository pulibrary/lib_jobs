# frozen_string_literal: true
module AbsoluteIds
  module Serializers
    class AbsoluteIdXmlSerializer < RecordXmlSerializer
      private

      def build_array_elements(element_name, enum_value)
        enum_element = document_tree.create_element(element_name)

        enum_value.each do |value|
          type_attribute = if value.is_a?(Hash)
                             'hash'
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
                           else
                             value.class.to_s.underscore
                           end

          new_element = if type_attribute == 'hash'
                          build_hash_element(child_element_name, value)
                        else
                          build_element(element_name: child_element_name, type_attribute: type_attribute, value: value)
                        end
          hash_element.add_child(new_element) unless new_element.nil?
        end

        hash_element
      end

      def build_element(element_name:, type_attribute:, value:)
        return if value.blank?

        return build_array_elements(element_name, value) if type_attribute == 'array'

        return build_hash_element(element_name, value) if type_attribute == 'hash'

        new_element = document_tree.create_element(element_name)
        new_element['type'] = type_attribute unless type_attribute.nil?
        new_element.content = value

        new_element
      end

      def build_document
        @document_tree = build_document_tree

        @model.attributes.each_pair do |key, value|
          element_name = key.to_s.underscore

          type_attribute = if value.is_a?(Hash)
                             'hash'
                           elsif value.is_a?(NilClass)
                             nil
                           elsif value.is_a?(ActiveSupport::TimeWithZone)
                             'time'
                           else
                             value.class.to_s.underscore
                           end
          new_element = build_element(element_name: element_name, type_attribute: type_attribute, value: value)

          root_element.add_child(new_element) unless new_element.nil?
        end

        document_tree
      end
    end
  end
end
