
class AbsoluteIdImporter

  def initialize(csv_file_path)
    @csv_file_path = csv_file_path
  end

  private

  def csv_file
    File.read(@csv_file_path)
  end

  def csv_table
    CSV.parse(csv_file, headers: true)
  end

  def csv_rows
    csv_table.to_a
  end

  def import
    AbsoluteIdBatchImportJob.perform_now(batch: csv_rows)
  end
end
