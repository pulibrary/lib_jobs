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

  namespace :absolute_ids do
    namespace :aspace do
      desc "caches ArchivesSpace resources"
      task :cache, [] => [:environment] do |t, args|
        ArchivesSpaceCacheJob.perform_later
      end
    end

    desc "import AbIDs from a CSV file"
    task :import, [:barcode_csv_file_path, :sequence_csv_file_path] => [:environment] do |t, args|
      importer = AbsoluteIdImporter.new(barcode_csv_file_path: args[:barcode_csv_file_path], sequence_csv_file_path: args[:sequence_csv_file_path])
      importer.import
    end
  end

  desc "Clean dead Sidekiq Queues."
  task :dead_queues, [] => [:environment] do |t, args|
    CleanDeadQueuesJob.set(queue: :low).perform_later
  end
end
