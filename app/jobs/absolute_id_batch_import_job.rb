
class AbsoluteIdBatchImportJob < ApplicationJob
  def perform(barcode_entries:, sequence_entries:)
    @barcode_entries = barcode_entries
    @sequence_entries = sequence_entries

    entries.each do |entry|
      AbsoluteIdImportJob.perform_now(entry)
    end
  end

  def barcode_rows
    return @barcode_rows unless @barcode_rows.nil?

    output = {}

    csv_entries = @barcode_entries[(1..-1)]
    csv_entries.each do |barcode_entry|
      primary_key = barcode_entry[0]
      output[primary_key] = barcode_entry[1]
    end

    @barcode_rows = output
  end

  def current_client
    return @current_client unless @current_client.nil?

    @current_client = LibJobs::ArchivesSpace::Client.source
    @current_client.login
    @current_client
  end

  def entries
    csv_entries = @sequence_entries[(1..-1)]
    csv_entries.map do |sequence_entry|
      # Barcode
      barcode_key = sequence_entry[1]
      barcode = barcode_rows[barcode_key]

      imported_attributes = {
        prefix: sequence_entry[2],
        index: sequence_entry[10],
        call_number: sequence_entry[11],
        repo_code: sequence_entry[12],
        barcode: barcode
      }

      # Is this needed?
      container_type = sequence_entry[13]

      imported_attributes
    end
  end
end
