# frozen_string_literal: false

module Gobi
  class IsbnFile
    attr_reader :received_items_file
    def initialize(temp_file:)
      @received_items_file = temp_file
    end

    def process
      CSV.foreach(received_items_file, headers: true, encoding: 'bom|utf-8') do |row|
        next unless published_within_five_years?(row:)
        next unless relevant_library_code?(row:)
        next if isbn_for_report(row:).blank?
        write_record(row:)
      end
      Gobi::IsbnReportJob.working_file_name
    end

    # with items published in the last 5 years
    #   Edge cases: 202u (sometime in the 2020s), 9999, publication dates in the future
    def published_within_five_years?(row:)
      pub_year = row["Begin Publication Date"]
      return false if pub_year == '9999' || pub_year.nil?

      pub_year.sub!('u', '0')
      return false if pub_year.to_i < Time.current.year - 5

      true
    end

    # that are not Library Code zobsolete, online, resshare
    def relevant_library_code?(row:)
      return true unless %w[zobsolete online resshare].include?(row["Library Code"])

      false
    end

    # Text files for Gobi must be either tab or pipe separated
    def write_record(row:)
      CSV.open(Gobi::IsbnReportJob.working_file_path, 'a', headers: true, encoding: 'bom|utf-8', col_sep: "\t") do |csv|
        csv << row_data(row:)
      end
    end

    def isbn_for_report(row:)
      isbns = row["ISBN Valid"].split("\; ").map { |isbn| isbn.delete(':') }
      # Use the first 13 digit ISBN
      isbns.find { |isbn| isbn.size == 13 }
    end

    def code_string(row:)
      location_combo = "#{row['Library Code']}$#{row['Location Code']}"
      limited_locations = Rails.application.config.gobi_locations.limited_locations
      shared_locations = Rails.application.config.gobi_locations.shared_locations
      if limited_locations.include?(location_combo)
        'NC'
      elsif shared_locations.include?(location_combo)
        'RCP'
      else
        'Cir'
      end
    end

    def row_data(row:)
      [
        isbn_for_report(row:),
        code_string(row:),
        Rails.application.config.gobi_sftp.gobi_account_code
      ]
    end
  end
end
