# frozen_string_literal: true
require 'csv'

module Shared
  # This class is responsible for checking the provided CSV data for the expected format/column headers
  class CSVValidator
    def require_headers(required_headers, csv_string: nil, csv_filename: nil, col_sep: ',')
      data, csv_filename = process_csv(csv_string:, csv_filename:, col_sep:)

      # Remove byte-order marks
      csv_headers = data.headers.compact.map { |header| header.delete('﻿') }

      return if csv_headers == ['The query resulted in no rows']
      raise InvalidHeadersError, "Missing required headers #{required_headers - csv_headers}\nFilename: #{csv_filename}" if (required_headers - csv_headers).any?

      true
    end

    class InvalidHeadersError < StandardError; end

    private

    def process_csv(csv_string:, csv_filename:, col_sep:)
      raise ArgumentError, 'csv_string and csv_filename are mutually exclusive' if csv_string && csv_filename
      raise ArgumentError, 'must supply csv_string or csv_filename' if csv_string.nil? && csv_filename.nil?

      if csv_string
        [CSV.new(csv_string, headers: true, col_sep:).read, 'In-memory string']
      else
        [CSV.read(csv_filename, headers: true, col_sep:), csv_filename]
      end
    end
  end
end
