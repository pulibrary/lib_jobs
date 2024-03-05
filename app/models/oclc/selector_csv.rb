# frozen_string_literal: false

module Oclc
  class SelectorCSV
    attr_reader :selector, :csv_file_path

    def initialize(selector_config:,
                   csv_file_path: Rails.application.config.newly_cataloged.selector_csv_path)
      @selector = Selector.new(selector_config:)
      @csv_file_path = csv_file_path
      Dir.mkdir(csv_file_path) unless Dir.exist?(csv_file_path)
    end

    def file_path
      date = Time.now.utc.strftime('%Y-%m-%d')
      selector_name = selector.name
      file_name = "#{date}-newly-cataloged-by-lc-#{selector_name}.csv"
      "#{csv_file_path}#{file_name}"
    end

    def create
      headers = ['OCLC Number', 'ISBNs', 'LCCNs', 'Author', 'Title', '008 Place Code',
                 'Pub Place', 'Pub Name', 'Pub Date', 'Description', 'Format', 'Languages',
                 'Call Number', 'Subjects', 'Non-Romanized Title']
      CSV.open(file_path, 'w', encoding: 'bom|utf-8') do |csv|
        csv.to_io.write "\uFEFF" # use CSV#to_io to write BOM directly
        csv << headers
      end
    end
  end
end
