
class AbsoluteIdImporter
  def initialize(barcode_csv_file_path:, sequence_csv_file_path:)
    @barcode_csv_file_path = barcode_csv_file_path
    @sequence_csv_file_path = sequence_csv_file_path
  end

  def import
    AbsoluteIdBatchImportJob.perform_now(barcode_entries: barcode_entries, sequence_entries: sequence_entries)
  end

  private

  def barcode_csv_file
    File.read(@barcode_csv_file_path)
  end

  def barcode_csv_table
    CSV.parse(barcode_csv_file, headers: true)
  end

  def barcode_entries
    barcode_csv_table.to_a
  end

  def sequence_csv_file
    File.read(@sequence_csv_file_path)
  end

  def sequence_csv_table
    CSV.parse(sequence_csv_file, headers: true)
  end

  def sequence_entries
    sequence_csv_table.to_a
  end
end
