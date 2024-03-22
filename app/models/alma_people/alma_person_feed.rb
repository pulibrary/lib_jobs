# frozen_string_literal: true
module AlmaPeople
  class AlmaPersonFeed < LibJob
    attr_reader :oit_person_feed, :begin_date, :end_date, :output_base_dir, :enabled_flag

    def initialize(oit_person_feed: AlmaPeople::OitPersonFeed.new, begin_date: 1.day.ago.strftime("%Y-%m-%d"),
                   end_date: Time.zone.now.strftime("%Y-%m-%d"), output_base_dir: ENV["ALMA_PERSON_FEED_OUTPUT_DIR"] || '/tmp',
                   enabled_flag: 'E')
      super(category: "AlmaPersonFeed")
      @oit_person_feed = oit_person_feed
      @begin_date = begin_date
      @end_date = end_date
      @output_base_dir = output_base_dir
      @enabled_flag = enabled_flag
      @ineligible_flag = 'I'
      @invalid_records = []
    end

    private

    def handle(data_set:)
      data_set.report_time = Time.zone.now.midnight
      oit_people = oit_person_feed.get_json(begin_date:, end_date:, enabled_flag:)
      full_path = build_xml(oit_people:, eligibility: enabled_flag)
      transfer_alma_person_file(filename: full_path)
      ineligible_user_message = ineligible_user if Flipflop.alma_person_ineligible?
      AlmaPeopleMailer.error_notification(invalid_records: @invalid_records).deliver
      data_set.data = "people_updated: #{oit_people.count}, file: #{File.basename(full_path)}"
      data_set.data << ineligible_user_message if Flipflop.alma_person_ineligible?
      data_set
    end

    def build_xml(oit_people:, eligibility:)
      return "" if oit_people.empty?

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.users do
          oit_people.each do |person|
            convert_person_to_xml(xml:, person:)
          end
        end
      end
      full_path = File.join(output_base_dir, output_filename(eligibility:))
      File.open(full_path, "w") do |file|
        file.write builder.to_xml
      end
      full_path
    end

    def transfer_alma_person_file(filename:)
      return if filename.blank?

      Zip::File.open(filename + '.zip', Zip::File::CREATE) do |zipfile|
        zipfile.add(File.basename(filename), filename)
      end
      alma_sftp = AlmaSftp.new
      alma_sftp.start do |sftp|
        sftp.upload!(filename + '.zip', File.join(Rails.application.config.alma_sftp.person_feed_path, "#{File.basename(filename)}.zip"))
      end
    end

    def convert_person_to_xml(xml:, person:)
      alma_person = AlmaPeople::AlmaXmlPerson.new(xml:, person:)
      if alma_person.valid?
        alma_person.convert
      else
        @invalid_records << alma_person
      end
    end

    def output_filename(eligibility:)
      date = begin_date || 1.day.ago.strftime("%Y-%m-%d")
      fname = ["alma_people", date, end_date, eligibility].compact.join('_')
      fname + ".xml"
    end

    def ineligible_user
      oit_people_ineligible = oit_person_feed.get_json(begin_date:, end_date:, enabled_flag: @ineligible_flag)
      full_path = build_xml(oit_people: oit_people_ineligible, eligibility: @ineligible_flag)
      transfer_alma_person_file(filename: full_path)
      ", ineligible_people_updated: #{oit_people_ineligible.count}, file: #{File.basename(full_path)}"
    end
  end
end
