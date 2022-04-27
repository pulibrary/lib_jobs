# frozen_string_literal: true
namespace :lib_jobs do
  desc "generate the daily staff report"
  task generate_staff_report: [:environment] do
    generator = WebStaff::StaffDirectoryGenerator.new(finance_report: WebStaff::FinanceReport.new, hr_report: WebStaff::HrStaffReport.new)
    generator.today
    today_report = File.new(WebStaff::StaffDirectoryGenerator.report_filename)
    yesterday_report = File.new(WebStaff::StaffDirectoryGenerator.yesterday_filename)
    differ = WebStaff::StaffDirectoryDifference.new(new_report: today_report, old_report: yesterday_report)
    differ.ids
  end

  desc "generate the daily alma people feed"
  task alma_daily_people_feed: [:environment] do
    feed = AlmaPeople::AlmaPersonFeed.new
    feed.run
  end

  desc "generate the full alma people feed"
  task alma_full_people_feed: [:environment] do
    feed = AlmaPeople::AlmaPersonFeed.new(begin_date: nil, end_date: nil)
    feed.run
  end

  desc "generate the voucher feed"
  task voucher_feed: [:environment] do
    feed = PeoplesoftVoucher::VoucherFeed.new
    feed.run
  end

  desc "move and convert the alma fund adjustment files"
  task alma_fund_adjustment: [:environment] do
    check = AlmaFundAdjustment::AdjustmentCheck.new
    if check.run
      transfer = AlmaFundAdjustment::FileConverter.new
      transfer.run
    end
  end

  desc "generate the alma invoice status updates"
  task alma_invoice_status_updates: [:environment] do
    convert = AlmaInvoiceStatus::FileConverter.new
    convert.run
  end

  desc "Clean dead Sidekiq Queues."
  task :dead_queues, [] => [:environment] do |_t, _args|
    CleanDeadQueuesJob.set(queue: :low).perform_later
  end

  desc "generate an alma people feed for a csv file"
  task alma_csv_person_update: [:environment] do
    if ENV["CSV_PERSON_FILE"].blank?
      puts "You must specify a file to process: CSV_PERSON_FILE=abc.csv bundle exec rake lib_jobs:alma_csv_person_update"
    else
      alma_person_query = AlmaPeople::AlmaQueryPersonCSV.new(csv_file: ENV["CSV_PERSON_FILE"])
      feed = AlmaPeople::AlmaPersonFeed.new(oit_person_feed: alma_person_query)
      feed.run
    end
  end

  desc "download, clean, and send MARCXML files for the POD project"
  task send_pod_records: [:environment] do
    file_pattern = ENV['FILE_PATTERN'] || '\.tar\.gz$'
    since = ENV['SINCE'] || Rails.application.config.pod.days_to_fetch.days.ago
    job = AlmaPodRecords::AlmaPodJob.new(file_pattern: file_pattern, since: since)
    job.run
  end

  desc "renew alma request via NCIP calls to Alma"
  task renew_alma_requests: [:environment] do
    job = AlmaRenew::RenewJob.new
    job.run
  end
end
