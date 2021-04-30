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
      task :cache, [] => [:environment] do |_t, _args|
        ArchivesSpace::CacheJob.perform_later
      end

      desc "clears the ArchivesSpace resource caches"
      task :clear_cache, [] => [:environment] do |_t, _args|
        ArchivesSpace::ClearCacheJob.perform_later
      end
    end

    desc "import AbIDs from a CSV file"
    task :import, [:barcode_csv_path, :sequence_csv_path] => [:environment] do |_t, args|
      importer = AbsoluteIds::Importer.new(
        barcode_csv_path: args[:barcode_csv_path],
        sequence_csv_path: args[:sequence_csv_path]
      )
      importer.import
    end
  end

  desc "Clean dead Sidekiq Queues."
  task :dead_queues, [] => [:environment] do |_t, _args|
    CleanDeadQueuesJob.set(queue: :low).perform_later
  end
end
