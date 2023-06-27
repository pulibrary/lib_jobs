# frozen_string_literal: true
require 'csv'

module AlmaFundAdjustment
  class AdjustmentCheck
    attr_reader :peoplesoft_input_base_dir, :peoplesoft_input_file_pattern

    # the inputs are ftp
    def initialize(peoplesoft_input_base_dir: Rails.application.config.peoplesoft.fund_adjustment_input_path,
                   peoplesoft_input_file_pattern: Rails.application.config.peoplesoft.fund_adjustment_input_file_pattern)
      @peoplesoft_input_base_dir = peoplesoft_input_base_dir
      @peoplesoft_input_file_pattern = peoplesoft_input_file_pattern.gsub("\\*", "*")
    end

    def run
      files = Dir.glob(File.join(peoplesoft_input_base_dir, peoplesoft_input_file_pattern))
      status = true
      files.each do |file|
        status &&= process_file(file)
      end
      status
    end

    private

    def process_file(file)
      return log_job_is_turned_off unless Flipflop.alma_fund_adjustment?
      status = true
      data = read_file(file)
      adjustments = data.map { |row| FundAdjustment.new(row) }
      ids = adjustments.map(&:unique_id)
      already_processed = ids.select { |id| PeoplesoftTransaction.where(transaction_id: id).count.positive? }
      if already_processed.count.positive?
        TransactionErrorMailer.report(duplicate_ids: already_processed).deliver
        File.rename(file, "#{file}.error")
        status = false
      else
        ids.each { |id| PeoplesoftTransaction.create(transaction_id: id) }
      end

      status
    end

    def read_file(file)
      CSVValidator.new(csv_filename: file)
                  .require_headers(['TRANSACTION_REFERENCE_NUMBER', 'TRANSACTION_NOTE', 'AMOUNT'])
      CSV.read(file, headers: true)
    end

    def log_job_is_turned_off
      data_set = DataSet.new(category: "FundAdjustment")
      data_set.data = 'Alma Fund Adjustment job is typically scheduled for this time, but it is turned off.  Go to /features to turn it back on.'
      data_set.report_time = Time.zone.now.midnight
      data_set.save
      false
    end
  end
end
