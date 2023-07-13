# frozen_string_literal: true

module Oclc
  class NewlyCatalogedFile
    attr_reader :data, :csv_file_path, :selectors

    def initialize(data:,
                   csv_file_path: Rails.application.config.newly_cataloged.selector_csv_path,
                   selectors: Rails.application.config.newly_cataloged.selectors)
      @data = data
      @csv_file_path = csv_file_path
      @selectors = selectors
    end

    def process
      data
      selectors.each do |selector|
        create_or_update_csv(selector:)
      end
    end

    # rubocop:disable Lint/UnusedBlockArgument
    def create_or_update_csv(selector:)
      date = Time.now.utc.strftime('%Y-%m-%d')
      selector_name = selector.keys.first.to_s
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
        selector
      end
    end

    def update_csv(file_path:, selector:)
      CSV.open(file_path, 'a', headers: true) do |csv|
        selector
      end
    end
    # rubocop:enable Lint/UnusedBlockArgument
  end
end
