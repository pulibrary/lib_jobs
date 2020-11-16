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
end
