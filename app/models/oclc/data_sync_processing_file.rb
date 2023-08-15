# frozen_string_literal: true

module Oclc
  class DataSyncProcessingFile
    attr_reader :temp_file, :file_date, :max_records_per_file
    def initialize(temp_file:)
      @temp_file = temp_file
      @file_date = Time.now.utc.strftime('%Y%m%d_%H%M%S%L')
      @record_accumulator = {}
      @max_records_per_file = Rails.application.config.oclc_sftp.max_records_per_file
      @file_num_iterator = 1
      @process_date = Time.now.utc.strftime('%Y%m%d')
    end

    def process
      accumulate_records
      write_marc_records
    end

    def accumulate_records
      File.readlines(temp_file).each do |line|
        mms_id = mms_id(line:)
        next if mms_id.zero?

        next if @record_accumulator.key?(mms_id)

        hash = line_record_hash(line:)
        next if hash[:action] == 'unresolved'

        @record_accumulator[mms_id] ||= []
        @record_accumulator[mms_id] << hash
      end
    end

    def mms_id(line:)
      line.chomp!
      parts = line.split('|')
      parts[1].to_i
    end

    def line_record_hash(line:)
      line.chomp!
      parts = line.split('|')
      hash = {}
      hash[:oclc_num] = parts[3]
      hash[:formatted_oclc_num] = format_oclc_number(parts[3])
      hash[:action] = parts[4]
      hash
    end

    def write_marc_records
      current_working_file_name = working_file_name
      rec_num = 0
      writer = nil
      @record_accumulator.each do |mms_id, record|
        writer = marc_writer(rec_num:, writer:)
        processing_record = marc_record(mms_id:, record:)
        writer.write(processing_record)
        rec_num += 1
      end
      writer&.close
      current_working_file_name
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
      working_file_directory = Rails.application.config.oclc_sftp.processing_working_directory
      FileUtils.mkdir_p(working_file_directory) unless File.exist?(working_file_directory)
      File.join(working_file_directory, working_file_name)
    end

    def working_file_name
      "xref_report_#{file_date}_#{@file_num_iterator}.mrc"
    end

    def marc_record(mms_id:, record:)
      record = record.first
      marc_record = MARC::Record.new
      marc_record.append(MARC::ControlField.new('001', mms_id.to_s))
      field = MARC::DataField.new('914', ' ', ' ')
      field.append(MARC::Subfield.new('a', record[:formatted_oclc_num]))
      field.append(MARC::Subfield.new('b', 'OCoLC'))
      field.append(MARC::Subfield.new('c', record[:action]))
      field.append(MARC::Subfield.new('d', @process_date))
      field.append(MARC::Subfield.new('e', 'unprocessed'))
      field.append(MARC::Subfield.new('f', record[:oclc_num]))
      marc_record.append(field)
      marc_record
    end

    def format_oclc_number(oclc_num)
      return oclc_num if /[^0-9]/.match?(oclc_num)

      number = oclc_num.to_i
      string = '(OCoLC)'
      string = string.dup
      string << if number < 99_999_999
                  "ocm#{number.to_s.rjust(8, '0')}"
                elsif number < 1_000_000_000
                  "ocn#{number}"
                else
                  "on#{number}"
                end
    end
  end
end
