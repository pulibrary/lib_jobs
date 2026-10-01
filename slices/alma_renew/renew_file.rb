# frozen_string_literal: true

require 'csv'

# Steps:
# 1. Make sure we have a slice for this job
# 2. Move this implementation into the slice directory
# 3. Move its test file into a spec/slice directory
# 4. Make sure the class is not single-use; if it is, refactor
# 5. Rather than calling Class.new() where this class is used, inject it using Slice['dependency_injection_key'] or Deps['dependency_injection_key']
# 6. Any other refactoring you feel like

module AlmaRenew
  class RenewFile
    def process(temp_file:)
      CSVValidator.new(csv_filename: temp_file.path).require_headers ['Barcode', 'Patron Group', 'Expiry Date', 'Primary Identifier']
      renew_item_list = []
      CSV.foreach(temp_file, headers: true, encoding: 'bom|utf-8') do |row|
        renew_item_list << Item.new(row.to_h)
      end
      renew_item_list
    end
  end
end
