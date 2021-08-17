# frozen_string_literal: true
require 'csv'

module AlmaPeople
  class AlmaQueryPersonCSV
    attr_reader :csv_file

    def initialize(csv_file:)
      @csv_file = csv_file
    end

    def get_json(*)
      ios = File.open(csv_file, "rb:bom|utf-8")
      data = ::CSV.parse(ios.read, headers: true)

      data.map do |input_row|
        convert_row_to_oit_person(input_row)
      end
    end

    private

    def convert_row_to_oit_person(input_row)
      {
        "PVPATRONGROUP" => input_row["user_group"].split(" ").first,
        "EMPLID" => input_row["primary_id"],
        "CAMPUS_ID" => input_row["user_title"],
        "PATRON_EXPIRATION_DATE" => input_row["expiration_date"],
        "PATRON_PURGE_DATE" => input_row["purge_date"],
        "PRF_OR_PRI_FIRST_NAM" => input_row["first_name"],
        "PRF_OR_PRI_LAST_NAME" => input_row["last_name"],
        "PRF_OR_PRI_MIDDLE_NAME" => input_row["middle_name"],
        "PU_BARCODE" => input_row["active_barcode"]
      }
    end
  end
end
