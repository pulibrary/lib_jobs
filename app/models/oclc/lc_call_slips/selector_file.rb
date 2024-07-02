# frozen_string_literal: true
require 'csv'
module Oclc
  module LcCallSlips
    class SelectorFile
      attr_reader :temp_file, :selectors_config

      def initialize(temp_file:,
                     selectors_config: Rails.application.config.lc_call_slips.selectors)
        @temp_file = temp_file
        @selectors_config = selectors_config
      end

      def process
        reader = MARC::Reader.new(temp_file.path, external_encoding: 'UTF-8')
        reader.each do |marc_record|
          record = Record.new(marc_record:)
          next unless record.generally_relevant?

          selectors_config.each do |selector_config|
            selector = Selector.new(selector_config:)
            next unless record.relevant_to_selector?(selector:)

            write_record_for_selector(record:, selector_config:)
          end
        end
      end

      def write_record_for_selector(record:, selector_config:)
        selector_csv = SelectorCSV.new(selector_config:)
        CSV.open(selector_csv.file_path, 'a', headers: true, encoding: 'bom|utf-8') do |csv|
          csv << row_data(record:)
        end
      end

      def row_data(record:)
        [
          record.oclc_id, record.isbns, record.lccns, record.author, record.title,
          record.f008_pub_place, record.pub_place, record.pub_name, record.pub_date,
          record.description, record.format, record.languages, record.call_number,
          record.subject_string, record.non_romanized_title
        ]
      end
    end
  end
end
