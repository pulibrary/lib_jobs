# frozen_string_literal: true
module Oclc
  class NewlyCatalogedFileAll
    attr_reader :temp_file

    def initialize(temp_file:)
      @temp_file = temp_file
    end

    def process
      reader = MARC::Reader.new(temp_file.path, external_encoding: 'UTF-8')
      reader.each do |marc_record|
        record = Record.new(marc_record:)
        next unless record.generally_relevant?

        write_record(record:)
      end
    end

    def write_record(record:)
      csv_path = NewlyCatalogedJobAll.all_records_file_path

      CSV.open(csv_path, 'a', headers: true, encoding: 'bom|utf-8') do |csv|
        csv << row_data(record:)
      end
    end

    def row_data(record:)
      [
        record.oclc_id, record.isbns, record.lccns, record.author, record.title,
        record.f008_pub_place, record.pub_place, record.pub_name, record.pub_date,
        record.description, record.format, record.languages, record.call_number,
        record.subject_string, record.non_romanized_title
      ]
    end
  end
end
