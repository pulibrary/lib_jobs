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
      Shared::Slice['csv_validator'].require_headers ['Barcode', 'Patron Group', 'Expiry Date', 'Primary Identifier'], csv_filename: temp_file.path
      CSV.foreach(temp_file, headers: true, encoding: 'bom|utf-8') do |row|
        renew_item_list << Item.new(row.to_h)
      end
      renew_item_list
    end
  end
end
