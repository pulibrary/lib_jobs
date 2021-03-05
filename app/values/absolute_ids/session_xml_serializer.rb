# frozen_string_literal: true
module AbsoluteIds
  class SessionXmlSerializer
    def initialize(model, _options = {})
      @model = model
    end

    def model_element_name
      "<#{@model.model_name.to_s.underscore} />"
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

    def build_document
      @document_tree = build_document_tree

      @model.batches.each do |batch|
        new_element_xml = batch.to_xml
        new_element_doc = Nokogiri::XML(new_element_xml)

        root_element.add_child(new_element_doc.root)
      end

      document_tree
    end

    def document
      @document ||= build_document
    end

    def serialize
      document.to_xml
    end
  end
end
