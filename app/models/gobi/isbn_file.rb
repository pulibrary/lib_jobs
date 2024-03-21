# frozen_string_literal: false

module Gobi
  class IsbnFile
    attr_reader :received_items_file, :bib_hash
    def initialize(temp_file:)
      @received_items_file = temp_file
      @bib_hash = {}
    end

    def process
      CSV.foreach(received_items_file, headers: true, encoding: 'bom|utf-8') do |row|
        next unless published_within_five_years?(row:)
        next unless relevant_library_code?(row:)
        isbns = isbns_for_report(row:)
        next if isbns.blank?
        build_bib_hash(row:)
      end
      write_bib_hash_to_csv
      Gobi::IsbnReportJob.working_file_name
    end

    def build_bib_hash(row:)
      bib_id = row["MMS Id"]
      if @bib_hash[bib_id]
        @bib_hash[bib_id][:loc_combos] << loc_combo(row:)
      else
        @bib_hash[bib_id] = {
          isbns: isbns_for_report(row:),
          loc_combos: [loc_combo(row:)]
        }
      end
    end

    def write_bib_hash_to_csv
      CSV.open(Gobi::IsbnReportJob.working_file_path, 'a', headers: true, encoding: 'bom|utf-8', col_sep: "|") do |csv|
        @bib_hash.each do |_bib, data|
          code_string = code_string(loc_combos: data[:loc_combos])
          data[:isbns].each do |isbn|
            csv << [isbn, code_string, Rails.application.config.gobi_sftp.gobi_account_code]
          end
        end
      end
    end

    def code_string(loc_combos:)
      limited_locations = Rails.application.config.gobi_locations.limited_locations
      shared_locations = Rails.application.config.gobi_locations.shared_locations
      has_limited_locations = (loc_combos & limited_locations)
      has_shared_locations = (loc_combos & shared_locations)
      has_circ_locations = (loc_combos - has_limited_locations - has_shared_locations).present?
      code_string = ''
      code_string << 'Cir' if has_circ_locations
      code_string << 'NC' if has_limited_locations.present?
      code_string << 'RCP' if has_shared_locations.present?
      code_string
    end

    def loc_combo(row:)
      library = row['Library Code']
      location = row['Location Code']
      [library, location].join('$')
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

    # Need to have a row for each valid ISBN
    # Could convert to 13 digit ISBN and de-dup
    def isbns_for_report(row:)
      isbns = row["ISBN Valid"].split("\; ").map { |isbn| isbn.delete(':') }
      isbns.select { |isbn| isbn.size == 13 || isbn.size == 10 }
    end
  end
end
