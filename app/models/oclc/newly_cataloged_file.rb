# frozen_string_literal: true

module Oclc
  class NewlyCatalogedFile
    attr_reader :temp_file, :selectors_config

    def initialize(temp_file:,
                   selectors_config: Rails.application.config.newly_cataloged.selectors)
      @temp_file = temp_file
      @selectors_config = selectors_config
    end

    def process
      selectors_config.each do |selector_config|
        selector = Selector.new(selector_config:)
        reader = MARC::Reader.new(temp_file.path, external_encoding: 'UTF-8')
        selector_csv = SelectorCSV.new(selector_config:)
        update_csv(file_path: selector_csv.file_path, selector:, reader:)
      end
    end

    def update_csv(file_path:, selector:, reader:)
      CSV.open(file_path, 'a', headers: true, encoding: 'bom|utf-8') do |csv|
        process_records_by_selector(selector:, csv:, reader:)
      end
    end

    def process_records_by_selector(selector:, csv:, reader:)
      reader.each do |marc_record|
        record = Record.new(marc_record:)

        Rails.logger.debug { "Record OCLC id: #{record.oclc_id}; Generally relevant? #{record.generally_relevant?}; Relevant to selector #{selector.name}: #{record.relevant_to_selector?(selector:)}" }
        next unless record.generally_relevant?

        next unless record.relevant_to_selector?(selector:)

        csv << row_data(record:)
      end
    end

    def row_data(record:)
      [
        record.oclc_id, record.isbns, record.lccns, record.author, record.title,
        record.f008_pub_place, record.pub_place, record.pub_name, record.pub_date,
        record.description, record.format, record.languages, record.call_number,
        record.subject_string
      ]
    end
  end
end
