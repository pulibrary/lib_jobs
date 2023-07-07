# frozen_string_literal: true
module PeoplesoftBursar
  class Report
    attr_reader :sftp_locations, :alma_sftp, :file_pattern, :input_ftp_base_dir, :list, :department, :report_type

    def initialize(input_ftp_base_dir: Rails.application.config.alma_sftp.bursar_report_path, file_pattern: '\.csv$', alma_sftp: AlmaSftp.new, list: nil, report_type: 'Generic')
      @input_ftp_base_dir = input_ftp_base_dir
      @file_pattern = file_pattern
      @alma_sftp = alma_sftp
      @sftp_locations = []
      @list = list || download_list
      @department = '41001'
      @report_type = report_type
    end

    def mark_files_as_processed
      return if sftp_locations.empty?

      alma_sftp.start do |sftp|
        sftp_locations.each do |location|
          sftp.rename(location, "#{location}.processed")
        end
      end
    end

    def total_amount
      @total_amount ||=
        begin
          total_amount = BigDecimal('0')
          list.each do |line|
            total_amount += line.amount
          end
          total_amount
        end
    end

    def total_lines
      list.size.to_s.rjust(10, '0')
    end

    def formatted_total
      format('%016.2<total>f', total: total_amount)
    end

    def to_s
      as_string = "#{total_lines} #{formatted_total} #{department} \n"
      list.each do |line|
        as_string += "#{line}\n"
      end
      as_string
    end

    def generate_bursar_file(out_fname)
      return if list.empty?

      File.open(out_fname, 'w') do |output|
        output.write(to_s)
      end
    end

    def heading
      return "No file to send." if list.empty?
      "Type: #{report_type}"
    end

    def subject_line
      'Alma to Peoplesoft Bursar Results'
    end

    def body
      return "" if list.empty?
      "Number of lines: #{list.size}\nTotal: #{formatted_total}"
    end

    def start_date
      @start_date ||= end_date - 7.days
    end

    def end_date
      @end_date ||= Time.zone.today
    end

    private

    def download_list
      list = []
      alma_sftp.start do |sftp|
        sftp.dir.foreach(input_ftp_base_dir) do |entry|
          next unless /#{file_pattern}/.match?(entry.name)
          filename = File.join(input_ftp_base_dir, entry.name)
          data = sftp.download!(filename)
          sftp_locations << filename
          list += parse_list(data)
        end
      end
      list
    end

    def parse_list(_data)
      raise "Need to implement parse_list in subclasses"
    end
  end
end
