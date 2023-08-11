# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaFundAdjustment::FileTransfer, type: :model do
  include_context 'sftp'

  subject(:file_transfer) do
    described_class.new(peoplesoft_input_base_dir: '/tmp', peoplesoft_input_file_pattern: 'test_alma*.csv',
                        alma_sftp: AlmaSftp.new(sftp_host: 'localhost', sftp_username: 'user', sftp_password: 'password'),
                        fund_adjustment_path: '/alma/fp')
  end

  describe "#run" do
    after do
      File.delete("/tmp/test_alma_1.csv") if File.exist?("/tmp/test_alma_1.csv")
      File.delete("/tmp/test_alma_2.csv") if File.exist?("/tmp/test_alma_2.csv")
      File.delete("/tmp/test_alma_1.csv.processed") if File.exist?("/tmp/test_alma_1.csv.processed")
      File.delete("/tmp/test_alma_2.csv.processed") if File.exist?("/tmp/test_alma_2.csv.processed")
    end

    it "transfers a file" do
      allow(sftp_session).to receive(:upload!)
      FileUtils.touch('/tmp/test_alma_1.csv')

      expect { expect(file_transfer.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
      expect(sftp_session).to have_received(:upload!).with("/tmp/test_alma_1.csv", '/alma/fp/test_alma_1.csv')
      data_set = DataSet.last
      expect(data_set.category).to eq("FundAdjustment")
      expect(data_set.data).to eq("Files processed: /tmp/test_alma_1.csv;  Error processing: None")
      expect(data_set.report_time).to eq(Time.zone.now.midnight)
      expect(File.exist?('/tmp/test_alma_1.csv.processed')).to be_truthy
    end

    it "transfers multiple files" do
      allow(sftp_session).to receive(:upload!).twice
      FileUtils.touch('/tmp/test_alma_1.csv')
      FileUtils.touch('/tmp/test_alma_2.csv')

      expect { expect(file_transfer.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
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
        FileUtils.touch('/tmp/test_alma_1.csv')

        expect { expect(file_transfer.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
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
        expect { expect(file_transfer.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
        data_set = DataSet.last
        expect(data_set.category).to eq("FundAdjustment")
        expect(data_set.data).to eq("Files processed: None;  Error processing: None")
        expect(data_set.report_time).to eq(Time.zone.now.midnight)
      end
    end

    context "file with only headers" do
      it "renames the file" do
        allow(sftp_session).to receive(:upload!)
        FileUtils.cp(Rails.root.join('spec', 'fixtures', 'fund_transactions_empty.csv'), '/tmp/test_alma_1.csv')

        expect { expect(file_transfer.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
        expect(sftp_session).to have_received(:upload!).with("/tmp/test_alma_1.csv", '/alma/fp/test_alma_1.csv')
        expect(File.exist?('/tmp/test_alma_1.csv.processed')).to be_truthy
      end
    end
  end
end
