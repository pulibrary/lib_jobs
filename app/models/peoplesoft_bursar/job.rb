# frozen_string_literal: true
module PeoplesoftBursar
  class Job < LibJob
    FILE_NAME = "libfines.dat"

    attr_reader :report, :output_base_dir

    def initialize(report:, output_base_dir: Rails.application.config.peoplesoft.bursar_output_path)
      super(category: "BursarReport")
      @report = report
      @output_base_dir = output_base_dir
    end

    def handle(data_set:)
      report.generate_bursar_file(File.join(output_base_dir, FILE_NAME))
      report.mark_files_as_processed

      FinanceMailer.bursar_report(report: report).deliver
      data_set.data = report.body
      data_set.report_time = Time.zone.now
      data_set
    end
  end
end
