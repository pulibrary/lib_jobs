# frozen_string_literal: true

module Oclc
  class DataSyncExceptionFile
    attr_reader :temp_file, :file_date, :max_records_per_file

    def initialize(temp_file:)
      @temp_file = temp_file
      @file_date = Time.now.utc.strftime('%Y%m%d_%H%M%S')
      @error_accumulator = {}
      @max_records_per_file = 6
      @file_num_iterator = 1
    end

    def process
      accumulate_errors
      write_marc_records
      true
    end

    def accumulate_errors
      temp_file.rewind
      File.readlines(temp_file).each do |line|
        mms_id = mms_id(line:)
        next if mms_id.zero?

        @error_accumulator[mms_id] ||= []
        @error_accumulator[mms_id] << line_error_hash(line:)
      end
    end

    def write_marc_records
      rec_num = 0
      writer = nil
      @error_accumulator.each do |mms_id, errors|
        writer = marc_writer(rec_num:, writer:)
        record = marc_record(mms_id, errors)
        writer.write(record)
        rec_num += 1
      end
      writer&.close
    end

    def marc_writer(rec_num:, writer:)
      if (rec_num % max_records_per_file).zero?
        writer&.close
        writer = MARC::Writer.new(working_file_path)
        @file_num_iterator += 1
      end
      writer
    end

    def working_file_path
      working_file_directory = 'spec/fixtures/oclc/'
      working_file_name = "datasync_errors_#{file_date}_#{@file_num_iterator}.mrc"
      "#{working_file_directory}#{working_file_name}"
    end

    def marc_record(mms_id, _errors)
      record = MARC::Record.new
      record.append(MARC::ControlField.new('001', mms_id.to_s))
      record
    end

    def mms_id(line:)
      line.chomp!
      parts = line.split('|')
      parts[1].to_i
    end

    def line_error_hash(line:)
      line.chomp!
      parts = line.split('|')
      le_hash = {}
      le_hash[:oclc_num] = parts[3]
      le_hash
    end
  end
end
