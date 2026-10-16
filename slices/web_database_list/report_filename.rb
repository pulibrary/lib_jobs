module WebDatabaseList
  # This class generates a new filename for a database list CSV
  class ReportFilename
    def call
      date_str = Time.zone.now.strftime('%Y%m%d%H%M')
      File.join(Rails.configuration.staff_directory['report_directory'], "library_databases_#{date_str}.csv")
    end
  end
end
