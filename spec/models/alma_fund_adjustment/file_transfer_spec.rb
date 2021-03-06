# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaFundAdjustment::FileTransfer, type: :model do
  subject(:fund_adjustment) do
    described_class.new(peoplesoft_input_base_dir: '/tmp', peoplesoft_input_file_pattern: 'test_alma*.csv',
                        alma_sftp: AlmaSftp.new(ftp_host: 'localhost', ftp_username: 'user', ftp_password: 'password'),
                        fund_adjustment_path: '/alma/fp')
  end
  let(:sftp_session) { instance_double("Net::SFTP::Session") }

  describe "#run" do
    after do
      File.delete("/tmp/test_alma_1.csv") if File.exist?("/tmp/test_alma_1.csv")
      File.delete("/tmp/test_alma_2.csv") if File.exist?("/tmp/test_alma_2.csv")
      File.delete("/tmp/test_alma_1.csv.processed") if File.exist?("/tmp/test_alma_1.csv.processed")
      File.delete("/tmp/test_alma_2.csv.processed") if File.exist?("/tmp/test_alma_2.csv.processed")
    end

    it "transfers a file" do
      allow(sftp_session).to receive(:upload!)
      allow(Net::SFTP).to receive(:start).and_yield(sftp_session) # start with also
      FileUtils.touch('/tmp/test_alma_1.csv')

      expect { expect(fund_adjustment.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
      expect(sftp_session).to have_received(:upload!).with("/tmp/test_alma_1.csv", '/alma/fp/test_alma_1.csv')
      data_set = DataSet.last
      expect(data_set.category).to eq("FundAdjustment")
      expect(data_set.data).to eq("Files processed: /tmp/test_alma_1.csv;  Error processing: None")
      expect(data_set.report_time).to eq(Time.zone.now.midnight)
      expect(File.exist?('/tmp/test_alma_1.csv.processed')).to be_truthy
    end

    it "transfers multiple files" do
      allow(sftp_session).to receive(:upload!).twice
      allow(Net::SFTP).to receive(:start).and_yield(sftp_session) # start with also
      FileUtils.touch('/tmp/test_alma_1.csv')
      FileUtils.touch('/tmp/test_alma_2.csv')

      expect { expect(fund_adjustment.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
      expect(sftp_session).to have_received(:upload!).with("/tmp/test_alma_1.csv", '/alma/fp/test_alma_1.csv')
      expect(sftp_session).to have_received(:upload!).with("/tmp/test_alma_2.csv", '/alma/fp/test_alma_2.csv')
      data_set = DataSet.last
      expect(data_set.category).to eq("FundAdjustment")
      expect(data_set.data).to eq("Files processed: /tmp/test_alma_1.csv, /tmp/test_alma_2.csv;  Error processing: None")
      expect(data_set.report_time).to eq(Time.zone.now.midnight)
      expect(File.exist?('/tmp/test_alma_1.csv.processed')).to be_truthy
      expect(File.exist?('/tmp/test_alma_2.csv.processed')).to be_truthy
    end

    context "handles an ftp error" do
      it "notes the error" do
        allow(sftp_session).to receive(:upload!).and_raise(Net::SFTP::StatusException, Net::SFTP::Response.new({}, { code: 500 }))
        allow(Net::SFTP).to receive(:start).and_yield(sftp_session)
        FileUtils.touch('/tmp/test_alma_1.csv')

        expect { expect(fund_adjustment.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
        expect(sftp_session).to have_received(:upload!).with("/tmp/test_alma_1.csv", '/alma/fp/test_alma_1.csv')
        data_set = DataSet.last
        expect(data_set.category).to eq("FundAdjustment")
        expect(data_set.data).to eq("Files processed: None;  Error processing: /tmp/test_alma_1.csv")
        expect(data_set.report_time).to eq(Time.zone.now.midnight)
        expect(File.exist?('/tmp/test_alma_1.csv.processed')).not_to be_truthy
        expect(File.exist?('/tmp/test_alma_1.csv')).to be_truthy
      end
    end

    context "no files" do
      it "notes that nothing was processed" do
        allow(Net::SFTP).to receive(:start).and_yield(sftp_session)

        expect { expect(fund_adjustment.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
        data_set = DataSet.last
        expect(data_set.category).to eq("FundAdjustment")
        expect(data_set.data).to eq("Files processed: None;  Error processing: None")
        expect(data_set.report_time).to eq(Time.zone.now.midnight)
      end
    end
  end
end
