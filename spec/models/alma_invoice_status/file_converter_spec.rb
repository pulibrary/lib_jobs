# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaInvoiceStatus::FileConverter, type: :model, file_upload: true do
  include_context 'sftp'

  subject(:fund_adjustment) do
    described_class.new(peoplesoft_input_base_dir: 'spec/fixtures/peoplesoft_4', peoplesoft_input_file_pattern: 'test_alma*.csv',
                        alma_sftp: AlmaSftp.new(sftp_host: 'localhost', sftp_username: 'user', sftp_password: 'password'),
                        invoice_status_path: '/alma/invoice_status')
  end
  let(:files_for_cleanup) do
    [
      'spec/fixtures/peoplesoft_4/test_alma_1.csv',
      'spec/fixtures/peoplesoft_4/test_alma_2.csv',
      'spec/fixtures/peoplesoft_4/test_alma_1.csv.processed',
      'spec/fixtures/peoplesoft_4/test_alma_2.csv.processed',
      'spec/fixtures/peoplesoft_4/test_alma_1.csv.converted',
      'spec/fixtures/peoplesoft_4/test_alma_2.csv.converted',
      'spec/fixtures/ephemeral/test_alma_1.csv',
      'spec/fixtures/ephemeral/test_alma_1.csv.converted',
      'spec/fixtures/ephemeral/test_alma_2.csv.converted'
    ]
  end
  around do |example|
    files_for_cleanup.each do |file_path|
      File.delete(file_path) if File.exist?(file_path)
    end
    example.run
    files_for_cleanup.each do |file_path|
      File.delete(file_path) if File.exist?(file_path)
    end
  end
  describe "#run" do
    it "transfers a file" do
      allow(sftp_session).to receive(:upload!)
      FileUtils.touch('spec/fixtures/peoplesoft_4/test_alma_1.csv')

      expect { expect(fund_adjustment.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
      expect(sftp_session).to have_received(:upload!).with("spec/fixtures/ephemeral/test_alma_1.csv.converted", "/alma/invoice_status/test_alma_1.csv")
      data_set = DataSet.last
      expect(data_set.category).to eq("InvoiceStatus")
      expect(data_set.data).to eq("Files processed: spec/fixtures/peoplesoft_4/test_alma_1.csv;  Error processing: None")
      expect(data_set.report_time).to eq(Time.zone.now.midnight)
      expect(File.exist?('spec/fixtures/peoplesoft_4/test_alma_1.csv.processed')).to be_truthy
    end

    it "transfers multiple files" do
      allow(sftp_session).to receive(:upload!).twice
      FileUtils.touch('spec/fixtures/peoplesoft_4/test_alma_1.csv')
      FileUtils.touch('spec/fixtures/peoplesoft_4/test_alma_2.csv')

      expect { expect(fund_adjustment.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
      expect(sftp_session).to have_received(:upload!).with("spec/fixtures/ephemeral/test_alma_1.csv.converted", '/alma/invoice_status/test_alma_1.csv')
      expect(sftp_session).to have_received(:upload!).with("spec/fixtures/ephemeral/test_alma_2.csv.converted", '/alma/invoice_status/test_alma_2.csv')
      data_set = DataSet.last
      expect(data_set.category).to eq("InvoiceStatus")
      expect(data_set.data).to eq("Files processed: spec/fixtures/peoplesoft_4/test_alma_1.csv, spec/fixtures/peoplesoft_4/test_alma_2.csv;  Error processing: None")
      expect(data_set.report_time).to eq(Time.zone.now.midnight)
      expect(File.exist?('spec/fixtures/peoplesoft_4/test_alma_1.csv.processed')).to be_truthy
      expect(File.exist?('spec/fixtures/peoplesoft_4/test_alma_2.csv.processed')).to be_truthy
    end

    context "handles an ftp error" do
      it "notes the error" do
        allow(sftp_session).to receive(:upload!).and_raise(Net::SFTP::StatusException, Net::SFTP::Response.new({}, { code: 500 }))
        FileUtils.touch('spec/fixtures/peoplesoft_4/test_alma_1.csv')

        expect { expect(fund_adjustment.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
        expect(sftp_session).to have_received(:upload!).with("spec/fixtures/ephemeral/test_alma_1.csv.converted", '/alma/invoice_status/test_alma_1.csv')
        data_set = DataSet.last
        expect(data_set.category).to eq("InvoiceStatus")
        expect(data_set.data).to eq("Files processed: None;  Error processing: spec/fixtures/peoplesoft_4/test_alma_1.csv")
        expect(data_set.report_time).to eq(Time.zone.now.midnight)
        expect(File.exist?('spec/fixtures/peoplesoft_4/test_alma_1.csv.processed')).not_to be_truthy
        expect(File.exist?('spec/fixtures/peoplesoft_4/test_alma_1.csv')).to be_truthy
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
        FileUtils.copy_file(alma_invoice_xml, 'spec/fixtures/ephemeral/test_alma_1.csv')
        expect { expect(fund_adjustment.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
        expect(sftp_session).to have_received(:upload!).with("spec/fixtures/ephemeral/test_alma_1.csv.converted", '/alma/invoice_status/test_alma_1.csv')
        expect(File.open('spec/fixtures/ephemeral/test_alma_1.csv.converted').read).to eq(File.open(Rails.root.join('alma_status_query_output.xml')).read)
      end
    end

    context "job is turned off" do
      before do
        allow(Flipflop).to receive(:alma_invoice_status?).and_return(false)
      end
      it "logs that it is turned off" do
        allow(sftp_session).to receive(:upload!)
        FileUtils.touch('spec/fixtures/ephemeral/test_alma_1.csv')

        fund_adjustment.run
        data_set = DataSet.last
        expect(data_set.data).to eq("Alma Invoice Status job is typically scheduled for this time, but it is turned off.  Go to /features to turn it back on.")
      end
    end
  end
end
