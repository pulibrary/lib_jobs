# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaInvoiceStatus::FileConverter, type: :model, focus: true do
  include_context 'sftp'

  subject(:fund_adjustment) do
    described_class.new(peoplesoft_input_base_dir: '/tmp', peoplesoft_input_file_pattern: 'test_alma*.csv',
                        alma_sftp: AlmaSftp.new(sftp_host: 'localhost', sftp_username: 'user', sftp_password: 'password'),
                        invoice_status_path: '/alma/fp')
  end

  describe "#run" do
    after do
      File.delete("/tmp/test_alma_1.csv") if File.exist?("/tmp/test_alma_1.csv")
      File.delete("/tmp/test_alma_2.csv") if File.exist?("/tmp/test_alma_2.csv")
      File.delete("/tmp/test_alma_1.csv.processed") if File.exist?("/tmp/test_alma_1.csv.processed")
      File.delete("/tmp/test_alma_2.csv.processed") if File.exist?("/tmp/test_alma_2.csv.processed")
      File.delete("/tmp/test_alma_1.csv.converted") if File.exist?("/tmp/test_alma_1.csv.converted")
      File.delete("/tmp/test_alma_2.csv.converted") if File.exist?("/tmp/test_alma_2.csv.converted")
    end

    it "transfers a file" do
      allow(sftp_session).to receive(:upload!)
      FileUtils.touch('/tmp/test_alma_1.csv')

      expect { expect(fund_adjustment.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
      expect(sftp_session).to have_received(:upload!).with("/tmp/test_alma_1.csv.converted", "/alma/fp/test_alma_1.csv")
      data_set = DataSet.last
      expect(data_set.category).to eq("InvoiceStatus")
      expect(data_set.data).to eq("Files processed: /tmp/test_alma_1.csv;  Error processing: None")
      expect(data_set.report_time).to eq(Time.zone.now.midnight)
      expect(File.exist?('/tmp/test_alma_1.csv.processed')).to be_truthy
    end

    it "transfers multiple files" do
      allow(sftp_session).to receive(:upload!).twice
      FileUtils.touch('/tmp/test_alma_1.csv')
      FileUtils.touch('/tmp/test_alma_2.csv')

      expect { expect(fund_adjustment.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
      expect(sftp_session).to have_received(:upload!).with("/tmp/test_alma_1.csv.converted", '/alma/fp/test_alma_1.csv')
      expect(sftp_session).to have_received(:upload!).with("/tmp/test_alma_2.csv.converted", '/alma/fp/test_alma_2.csv')
      data_set = DataSet.last
      expect(data_set.category).to eq("InvoiceStatus")
      expect(data_set.data).to eq("Files processed: /tmp/test_alma_1.csv, /tmp/test_alma_2.csv;  Error processing: None")
      expect(data_set.report_time).to eq(Time.zone.now.midnight)
      expect(File.exist?('/tmp/test_alma_1.csv.processed')).to be_truthy
      expect(File.exist?('/tmp/test_alma_2.csv.processed')).to be_truthy
    end

    context "handles an ftp error" do
      it "notes the error" do
        allow(sftp_session).to receive(:upload!).and_raise(Net::SFTP::StatusException, Net::SFTP::Response.new({}, { code: 500 }))
        FileUtils.touch('/tmp/test_alma_1.csv')

        expect { expect(fund_adjustment.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
        expect(sftp_session).to have_received(:upload!).with("/tmp/test_alma_1.csv.converted", '/alma/fp/test_alma_1.csv')
        data_set = DataSet.last
        expect(data_set.category).to eq("InvoiceStatus")
        expect(data_set.data).to eq("Files processed: None;  Error processing: /tmp/test_alma_1.csv")
        expect(data_set.report_time).to eq(Time.zone.now.midnight)
        expect(File.exist?('/tmp/test_alma_1.csv.processed')).not_to be_truthy
        expect(File.exist?('/tmp/test_alma_1.csv')).to be_truthy
      end
    end

    context "no files" do
      it "notes that nothing was processed" do
        expect { expect(fund_adjustment.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
        data_set = DataSet.last
        expect(data_set.category).to eq("InvoiceStatus")
        expect(data_set.data).to eq("Files processed: None;  Error processing: None")
        expect(data_set.report_time).to eq(Time.zone.now.midnight)
      end
    end

    context "with real data locally" do
      let(:alma_invoice_xml) { Rails.root.join('PU_AP_ALMA_INVOICE_DETAILS_06142021.xml') }
      it "generates xml" do
        pending "Should only be run locally"
        allow(sftp_session).to receive(:upload!)
        FileUtils.copy_file(alma_invoice_xml, '/tmp/test_alma_1.csv')
        expect { expect(fund_adjustment.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
        expect(sftp_session).to have_received(:upload!).with("/tmp/test_alma_1.csv.converted", '/alma/fp/test_alma_1.csv')
        expect(File.open('/tmp/test_alma_1.csv.converted').read).to eq(File.open(Rails.root.join('alma_status_query_output.xml')).read)
      end
    end

    context "job is turned off" do
      before do
        allow(Flipflop).to receive(:alma_invoice_status?).and_return(false)
      end
      it "logs that it is turned off" do
        allow(sftp_session).to receive(:upload!)
        FileUtils.touch('/tmp/test_alma_1.csv')

        fund_adjustment.run
        data_set = DataSet.last
        expect(data_set.data).to eq("Alma Invoice Status job is typically scheduled for this time, but it is turned off.  Go to /features to turn it back on.")
      end
    end
  end
end
