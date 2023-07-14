# frozen_string_literal: true

module Oclc
  class NewlyCatalogedFile
    attr_reader :temp_file, :csv_file_path, :selectors_config, :reader

    def initialize(temp_file:,
                   csv_file_path: Rails.application.config.newly_cataloged.selector_csv_path,
                   selectors_config: Rails.application.config.newly_cataloged.selectors)
      @temp_file = temp_file
      @csv_file_path = csv_file_path
      @selectors_config = selectors_config
      @reader = MARC::Reader.new(temp_file.path)
    end

    def process
      selectors_config.each do |selector_config|
        selector = Selector.new(selector_config:)
        create_or_update_csv(selector:)
      end
    end

    # rubocop:disable Lint/UnusedBlockArgument
    # rubocop:disable Lint/UnusedMethodArgument
    def create_or_update_csv(selector:)
      date = Time.now.utc.strftime('%Y-%m-%d')
      selector_name = selector.name
      file_name = "#{date}-newly-cataloged-by-lc-#{selector_name}.csv"
      file_path = "#{csv_file_path}#{file_name}"
      if File.exist?(file_path)
        update_csv(file_path:, selector:)
      else
        create_csv(file_path:, selector:)
      end
    end

    def create_csv(file_path:, selector:)
      headers = ['OCLC Number', 'ISBNs', 'LCCNs', 'Author', 'Title', '008 Place Code',
                 'Pub Place', 'Pub Name', 'Pub Date', 'Description', 'Format', 'Languages',
                 'Call Number', 'Subjects']
      CSV.open(file_path, 'w', headers:, write_headers: true) do |csv|
        process_records_by_selector(selector:, csv:)
      end
    end

    def update_csv(file_path:, selector:)
      CSV.open(file_path, 'a', headers: true) do |csv|
        process_records_by_selector(selector:, csv:)
      end
    end

    def process_records_by_selector(selector:, csv:)
      @reader.each do |marc_record|
        record = Record.new(marc_record:)
        next unless record.generally_relevant?

        next unless record.relevant_to_selector?(selector:)
      end
    end
    # rubocop:enable Lint/UnusedBlockArgument
    # rubocop:enable Lint/UnusedMethodArgument
  end
end
