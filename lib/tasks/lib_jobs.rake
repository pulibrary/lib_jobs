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
    desc "import AbIDs from a CSV file"
    task :import, [:csv_file_path] => [:environment] do |t, args|
      importer = AbsoluteIdImporter.new(csv_file_path: args[:csv_file_path])
      importer.import
    end
  end
end
