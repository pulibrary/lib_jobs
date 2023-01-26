# frozen_string_literal: true
require 'csv'

class CSVValidator
  def initialize(csv_string: nil, csv_filename: nil, col_sep: ',')
    raise ArgumentError, 'csv_string and csv_filename are mutually exclusive' if csv_string && csv_filename
    raise ArgumentError, 'must supply csv_string or csv_filename' if csv_string.nil? && csv_filename.nil?
    if csv_string
      @data = CSV.parse(csv_string, headers: true, col_sep:)
      @csv_filename = 'In-memory string'
    else
      @data = CSV.read(csv_filename, headers: true, col_sep:)
      @csv_filename = csv_filename
    end
  end

  def require_headers(required_headers)
    return if csv_headers == ['The query resulted in no rows']
    raise InvalidHeadersError, "Missing required headers #{required_headers - csv_headers}\nFilename: #{@csv_filename}" if (required_headers - csv_headers).any?

    true
  end

  class InvalidHeadersError < StandardError; end

  private

  def csv_headers
    # Remove byte-order marks
    @data.headers.compact.map { |header| header.delete('﻿') }
  end
end
