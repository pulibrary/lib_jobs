# frozen_string_literal: true

require 'csv'

module AlmaRenew
  class RenewFile
    attr_reader :temp_file, :renew_item_list
    def initialize(temp_file:)
      @temp_file = temp_file
      @renew_item_list = []
    end

    def process
      CSVValidator.new(csv_filename: temp_file.path).require_headers ['Barcode', 'Patron Group', 'Expiry Date', 'Primary Identifier']
      CSV.foreach(temp_file, headers: true, encoding: 'bom|utf-8') do |row|
        renew_item_list << Item.new(row.to_h)
      end
      renew_item_list
    end
  end
end
