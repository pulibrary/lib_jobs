# frozen_string_literal: true

# This class moves files from a samba share populated by PeopleSoft into the sftp directory Alma needs
#  No data transformation is done.
module AlmaInvoiceStatus
  class FileConverter < AlmaFundAdjustment::FileTransfer
    attr_reader :alma_invoice_status_path, :output_base_dir, :local_filename

    # inputs is an Finance samba share
    # the output is the alma ftp server
    def initialize(peoplesoft_input_base_dir: Rails.application.config.peoplesoft.invoice_status_input_path,
                   peoplesoft_input_file_pattern: Rails.application.config.peoplesoft.invoice_status_input_file_pattern,
                   alma_sftp: AlmaSftp.new, invoice_status_path: Rails.application.config.alma_sftp.invoice_status_path,
                   output_base_dir: Rails.application.config.alma_sftp.invoice_status_local_path)
      super(peoplesoft_input_base_dir:, peoplesoft_input_file_pattern:,
            alma_sftp:)
      @category = "InvoiceStatus"
      @alma_invoice_status_path = invoice_status_path
      @output_base_dir = output_base_dir
    end

    private

    def handle(data_set:)
      return log_job_is_turned_off unless Flipflop.alma_invoice_status?
      super(data_set:)
    end

    def log_job_is_turned_off
      data_set = DataSet.new(category: "InvoiceStatus")
      data_set.data = 'Alma Invoice Status job is typically scheduled for this time, but it is turned off.  Go to /features to turn it back on.'
      data_set.report_time = Time.zone.now.midnight
      data_set.save
      data_set
    end

    def process_file(path, sftp)
      query = File.open(path) { |f| StatusQuery.new(xml_io: f) }
      alma_xml = AlmaXml.new(invoices: query.invoices)
      local_filename = File.join(output_base_dir, "#{File.basename(path)}.converted")
      File.open(local_filename, 'w') { |output| output.puts(alma_xml.build) }
      sftp.upload!(local_filename, File.join(alma_invoice_status_path, File.basename(path)))
      File.rename(path, "#{path}.processed")
    end
  end
end
