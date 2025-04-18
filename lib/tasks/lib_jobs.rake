# frozen_string_literal: true
namespace :lib_jobs do
  desc "generate the daily staff report"
  task generate_staff_report: [:environment] do
    generator = WebStaff::StaffDirectoryGenerator.new(hr_report: WebStaff::HrStaffReport.new)
    generator.today
    today_report = File.new(WebStaff::StaffDirectoryGenerator.report_filename)
    yesterday_report = File.new(WebStaff::StaffDirectoryGenerator.yesterday_filename)
    differ = WebStaff::StaffDirectoryDifference.new(new_report: today_report, old_report: yesterday_report)
    differ.ids
  end

  desc "generate the events feed csv"
  task generate_events_csv: [:environment] do
    generator = WebEvents::EventsFeedGenerator.new
    generator.run
  end

  desc "generate the A-Z database list csv"
  task generate_database_list_csv: [:environment] do
    feed = WebDatabaseList::DatabasesFeed.new
    feed.run
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
    job = AlmaPodRecords::AlmaPodJob.new(file_pattern:, since:)
    job.run
  end

  desc "renew alma request via NCIP calls to Alma"
  task renew_alma_requests: [:environment] do
    job = AlmaRenew::RenewJob.new
    job.run
  end

  desc "process credits paid on fines and send them to the bursar"
  task process_bursar_credits: [:environment] do
    credit_report = PeoplesoftBursar::CreditReport.new
    job = PeoplesoftBursar::Job.new(report: credit_report)
    job.run
  end

  desc "process fines and send them to the bursar"
  task process_bursar_fines: [:environment] do
    fine_report = PeoplesoftBursar::FineReport.new
    job = PeoplesoftBursar::Job.new(report: fine_report)
    job.run
  end

  desc "remove temporary files from temp directories"
  task clear_out_temp_directories: [:environment] do
    person_feed_dir = ENV["ALMA_PERSON_FEED_OUTPUT_DIR"] || '/tmp'
    pod_dir = Rails.application.config.pod.pod_record_path
    fund_adjustment_dir = Rails.application.config.peoplesoft.fund_adjustment_converted_path
    oclc_working_files_dir = Rails.application.config.oclc_sftp.exceptions_working_directory

    # Production directories
    directories = ['/tmp', person_feed_dir, pod_dir, fund_adjustment_dir, oclc_working_files_dir].uniq
    # Directory for testing
    # directories = ['./tmp']
    directories.each do |dir_path|
      puts("Deleting files older than 1 week in #{dir_path}")
      all_files = Dir.glob(File.join(dir_path, '*')).select { |f| File.file?(f) }
      old_files = all_files.select { |file| File.mtime(file) < (1.week.ago) }
      old_files.each do |file|
        puts("Deleting file: #{file}, last updated: #{File.mtime(file)}")
        FileUtils.rm_rf(file)
      end
    end
  end

  desc "send ead files from aspace to svn"
  task send_eads: [:environment] do
    job = AspaceVersionControl::GetEadsJob.new
    job.run
  end

  desc "POSTs to Alma to move OCLC numbers from the 914 field to the 035 field"
  task alma_bib_norm: [:environment] do
    job = AlmaBibNorm::AlmaBibNorm.new
    job.run
  end

  desc "process single file of newly cataloged records from OCLC and create CSV"
  task process_one_file_newly_cataloged_records: [:environment] do
    file = File.new(ENV['NEW_RECORDS_PATH'])
    newly_cataloged_file = Oclc::LcCallSlips::SelectorFile.new(temp_file: file)
    newly_cataloged_file.process
  end

  desc "process newly cataloged records from OCLC and create CSVs to send to selectors"
  task process_newly_cataloged_records: [:environment] do
    job = Oclc::LcCallSlips::SelectorJob.new
    job.run
  end

  desc "create a CSV of all generally relevant records for selectors to compare"
  task create_csv_for_selector_comparison: [:environment] do
    job = Oclc::LcCallSlips::AllRelevantJob.new
    job.run
  end

  desc "download data sync exceptions from oclc_sftp, process, and upload to lib-sftp"
  task process_data_sync_exceptions: [:environment] do
    job = Oclc::DataSyncExceptionJob.new
    job.run
  end

  desc "download data sync processed from oclc_sftp, process, and upload to lib-sftp"
  task process_data_sync_processed: [:environment] do
    job = Oclc::DataSyncProcessingJob.new
    job.run
  end

  desc "Submit collection: download PUL records from ALMA and upload them to SCSB"
  task process_submit_collection: [:environment] do
    job = AlmaSubmitCollection::AlmaSubmitCollectionJob.new
    job.run
  end

  desc "Gobi ISBN update: Download CSV of newly received records from lib-sftp, create new CSV to upload to Gobi"
  task gobi_isbn_update: [:environment] do
    job = Gobi::IsbnReportJob.new
    job.run
  end
end
