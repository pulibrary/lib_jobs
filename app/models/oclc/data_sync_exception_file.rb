# frozen_string_literal: true

module Oclc
  class DataSyncExceptionFile
    attr_reader :temp_file, :file_date, :max_records_per_file

    def initialize(temp_file:)
      @temp_file = temp_file
      @file_date = Time.now.utc.strftime('%Y%m%d_%H%M%S')
      @error_accumulator = {}
      @max_records_per_file = Rails.application.config.oclc_sftp.max_records_per_file
      @file_num_iterator = 1
      @process_date = Time.now.utc.strftime('%Y%m%d')
    end

    # Returns working_file_name, which will also be the file name
    # once uploaded to lib-sftp
    def process
      accumulate_errors
      clean_errors
      write_marc_records
    end

    def accumulate_errors
      File.readlines(temp_file).each do |line|
        mms_id = mms_id(line:)
        next if mms_id.zero?

        @error_accumulator[mms_id] ||= []
        @error_accumulator[mms_id] << line_error_hash(line:)
      end
    end

    def clean_errors
      @error_accumulator.each do |_mms, errors|
        errors.delete_if { |error| error[:error_text]&.match?(/invalid subfield.*\$0/i) }
        errors.uniq!
      end
      @error_accumulator.delete_if { |_mms, errors| errors.empty? }
    end

    def write_marc_records
      current_working_file_name = working_file_name
      rec_num = 0
      writer = nil
      @error_accumulator.each do |mms_id, errors|
        writer = marc_writer(rec_num:, writer:)
        record = marc_record(mms_id:, errors:)
        writer.write(record)
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
      working_file_directory = Rails.application.config.oclc_sftp.exceptions_working_directory
      FileUtils.mkdir_p(working_file_directory) unless File.exist?(working_file_directory)
      File.join(working_file_directory, working_file_name)
    end

    def working_file_name
      "datasync_errors_#{file_date}_#{@file_num_iterator}.mrc"
    end

    def marc_record(mms_id:, errors:)
      record = MARC::Record.new
      record.append(MARC::ControlField.new('001', mms_id.to_s))
      errors.each do |error|
        field = MARC::DataField.new('915', ' ', ' ')
        field.append(MARC::Subfield.new('a', error[:error_type]))
        field.append(MARC::Subfield.new('b', error[:error_severity]))
        field.append(MARC::Subfield.new('c', error[:error_text]))
        field.append(MARC::Subfield.new('d', @process_date))
        field.append(MARC::Subfield.new('e', error[:oclc_num]))
        record.append(field)
      end
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
      hash = {}
      hash[:oclc_num] = parts[3]
      hash[:error_type] = parts[4]
      hash[:error_severity] = parts[5]
      hash[:error_text] = parts[6]
      hash
    end
  end
end
