# frozen_string_literal: true
namespace :lib_jobs do
  desc "generate the daily staff report"
  task generate_staff_report: [:environment] do
    generator = StaffDirectoryGenerator.new(finance_report: FinanceReport.new, hr_report: HrStaffReport.new)
    generator.today
    today_report = File.new(StaffDirectoryGenerator.report_filename)
    yesterday_report = File.new(StaffDirectoryGenerator.yesterday_filename)
    differ = StaffDirectoryDifference.new(new_report: today_report, old_report: yesterday_report)
    differ.ids
  end

  desc "generate the daily alma people feed"
  task alma_daily_people_feed: [:environment] do
    feed = AlmaPersonFeed.new
    feed.run
  end

  desc "generate the full alma people feed"
  task alma_full_people_feed: [:environment] do
    feed = AlmaPersonFeed.new(begin_date: nil, end_date: nil)
    feed.run
  end

  namespace :absolute_ids do
    namespace :aspace do
      desc "caches ArchivesSpace resources"
      task :cache, [] => [:environment] do |t, args|
        Rails.logger.info("Caching locations...")
        source_client.locations.each do |location|
          location.cache
          Rails.logger.info("Cached location #{location.uri}...")
        end

        Rails.logger.info("Caching container profile...")
        source_client.container_profiles.each do |container_profile|
          container_profile.cache
          Rails.logger.info("Cached container profile #{container_profile.uri}...")
        end

        Rails.logger.info("Caching repositories...")
        source_client.repositories.each do |repository|
          repository.cache
          Rails.logger.info("Cached repository #{repository.uri}...")

          repository.top_containers.each do |top_container|
            top_container.cache
            Rails.logger.info("Cached container #{top_container.uri}...")
          end

          repository.resources.each do |resource|
            resource.cache
            Rails.logger.info("Cached resource #{resource.uri}...")
          end
        end
      end
    end

    desc "import AbIDs from a CSV file"
    task :import, [:barcode_csv_file_path, :sequence_csv_file_path] => [:environment] do |t, args|
      importer = AbsoluteIdImporter.new(barcode_csv_file_path: args[:barcode_csv_file_path], sequence_csv_file_path: args[:sequence_csv_file_path])
      importer.import
    end

  end
end

def source_client
  @source_client ||= begin
                       source_client = LibJobs::ArchivesSpace::Client.source
                       Rails.logger.info("Authenticating...")
                       source_client.login
                       Rails.logger.info("Authenticated")
                       source_client
                     end
end
