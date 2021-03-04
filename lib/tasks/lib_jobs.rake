# frozen_string_literal: true
namespace :lib_jobs do
  desc "generate the daily staff report"
  task generate_report: [:environment] do
    generator = StaffDirectoryGenerator.new(finance_report: FinanceReport.new, hr_report: HrStaffReport.new)

    report_filename = File.join(Rails.configuration.staff_directory['report_directory'], Rails.configuration.staff_directory['report_name'])
    yesterday = Date.yesterday.strftime("%Y%m%d")
    yesterday_report = "#{report_filename}_#{yesterday}"
    File.rename(report_filename, yesterday_report) if File.exist?(report_filename) && !File.exist?(yesterday_report)
    File.open(report_filename, "w") do |file|
      file.write(generator.report)
    end
    Rails.configuration.staff_directory['difference_name']
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
