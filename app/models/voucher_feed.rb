# frozen_string_literal: true
class VoucherFeed < LibJob
  attr_reader :peoplesoft_output_base_dir, :finance_invoices, :alma_xml_invoice_list, :onbase_output_base_dir

  # all outputs are samba shares
  # the inputs
  def initialize(alma_xml_invoice_list: AlmaXmlInvoiceList.new, onbase_output_base_dir: ENV["VOUCHER_FEED_ONBASE_OUTPUT_DIR"] || '/tmp',
                 peoplesoft_output_base_dir: ENV["VOUCHER_FEED_PEOPLESOFT_OUTPUT_DIR"] || '/tmp')
    super(category: "VoucherFeed")
    @finance_invoices = []
    @alma_xml_invoice_list = alma_xml_invoice_list
    @peoplesoft_output_base_dir = peoplesoft_output_base_dir
    @onbase_output_base_dir = onbase_output_base_dir
    # what files do I process in the input directory
    # change the name to .proccessed
    # Do I move or modify the file after processing (Yes, change the name to .proccessed)
    # If there are errors do I flag the errors and send the data long, or do I not send anything?
    # send the valid one, but not the invalid
  end

  private

  def handle(data_set:)
    build_peoplesoft_report
    build_onbase_report
    # send emails here.  The emailed file should.  Nicely formatted table in the email, one for errors & one for valid lines
    # need the US Currency (total_local_amount), also need currency & original amount
    # There is another file that needs to be made for onbase  - Mark will send an example "Library Invoice Keyword Update_20210427.csv" (need format)
    # this is the same data that should be in the email except for the currency).  Onbase file only includes successes and email gets two tables onbase and errors.
    # needs to be the original currency (total_invoice_amount)

    alma_xml_invoice_list.mark_files_as_processed
    FinanceMailer.report(alma_xml_invoice_list: alma_xml_invoice_list).deliver
    data_set.data = alma_xml_invoice_list.status_report
    data_set.report_time = Time.zone.now.midnight
    data_set
  end

  def build_onbase_report
    return if alma_xml_invoice_list.empty?
    full_path = File.join(onbase_output_base_dir, onbase_output_filename)
    File.open(full_path, "w") do |file|
      file.write alma_xml_invoice_list.onbase_report
    end
    full_path
  end

  def build_peoplesoft_report
    return if alma_xml_invoice_list.empty?
    builder = Nokogiri::XML::Builder.new do |xml|
      finance_invoice = FinanceXmlInvoice.new(xml: xml, alma_invoice_list: alma_xml_invoice_list)
      finance_invoice.convert
    end
    full_path = File.join(peoplesoft_output_base_dir, output_filename)
    File.open(full_path, "w") do |file|
      file.write builder.to_xml
    end
    full_path
  end

  # def mark_files_as_processed
  #   Net::SFTP.start(ftp_host, ftp_username, { password: ftp_password }) do |sftp|
  #     alma_invoice_list.sftp_locations.each do |location|
  #       sftp.rename(location, "#{location}.processed")
  #     end
  #   end
  # end

  # def alma_invoice_list
  #   @alma_invoice_list ||= begin
  #                            list = nil
  #                            Net::SFTP.start(ftp_host, ftp_username, { password: ftp_password }) do |sftp|
  #                              sftp.dir.foreach(input_ftp_base_dir) do |entry|
  #                                next unless /#{file_pattern}/.match?(entry.name)
  #                                filename = File.join(input_ftp_base_dir, entry.name)
  #                                data = sftp.download!(filename)
  #                                current_list = AlmaXmlInvoiceList.new(xml_file: StringIO.new(data), sftp_location: filename)
  #                                if list.blank?
  #                                  list = current_list
  #                                else
  #                                  list.merge(current_list)
  #                                end
  #                              end
  #                            end
  #                            list
  #                          end
  # end

  def output_filename
    date = Time.zone.now.strftime("%m%d%Y")
    "alma_voucher_#{date}.XML"
  end

  def onbase_output_filename
    date = Time.zone.now.strftime("%Y%m%d")
    "Library Invoice Keyword Update_#{date}.csv"
  end
end
