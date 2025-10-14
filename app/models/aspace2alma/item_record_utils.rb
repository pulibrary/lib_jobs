# frozen_string_literal: true
module Aspace2alma
  module ItemRecordUtils
    REPO_PATH_REGEX = %r{(^/repositories/)(\d{1,2})(/resources.*$)}

    def self.extract_repository_id(resource)
      resource.gsub(REPO_PATH_REGEX, '\2')
    end

    def self.sort_containers_by_indicator(containers)
      containers.sort_by do |container|
        JSON.parse(container['json'])['indicator'].scan(/\d+/).first.to_i
      end
    end

    def self.log_container_creation(log_out, json)
      log_out.puts "Created record for #{json['type']} #{json['indicator']}"
    end

    def self.add_item_record_to_doc(doc, top_container, tag099_a)
      doc.xpath('//marc:datafield').last.next = top_container.item_record(tag099_a.content)
    end

    def self.create_and_log_item_record(container, top_container, params)
      add_item_record_to_doc(params.doc, top_container, params.tag099_a)
      json = JSON.parse(container['json'])
      log_container_creation(params.log_out, json)
    end
  end
end
