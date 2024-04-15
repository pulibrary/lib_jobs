# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaFundAdjustment::FileConverter, type: :model, file_upload: true do
  include_context 'sftp'

  subject(:fund_adjustment) do
    described_class.new(peoplesoft_input_base_dir: 'spec/fixtures/peoplesoft_2', peoplesoft_input_file_pattern: 'test_alma*.csv',
                        fund_adjustment_path: '/alma/fund_adjustment',
                        sftp: AlmaSftp.new(sftp_host: 'localhost', sftp_username: 'user', sftp_password: 'password'))
  end
  let(:files_for_cleanup) do
    [
      'spec/fixtures/peoplesoft_2/test_alma_1.csv',
      'spec/fixtures/peoplesoft_2/test_alma_2.csv',
      'spec/fixtures/peoplesoft_2/test_alma_1.csv.processed',
      'spec/fixtures/peoplesoft_2/test_alma_2.csv.processed',
      'spec/fixtures/ephemeral_2/test_alma_1.csv',
      'spec/fixtures/ephemeral_2/test_alma_2.csv'
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
      FileUtils.cp(Rails.root.join('spec', 'fixtures', 'fund_transactions-2012-07-19-09-09-00.csv'), 'spec/fixtures/peoplesoft_2/test_alma_1.csv')

      expect { expect(fund_adjustment.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
      expect(sftp_session).to have_received(:upload!).with("spec/fixtures/ephemeral_2/test_alma_1.csv", '/alma/fund_adjustment/test_alma_1.csv')
      data_set = DataSet.last
      expect(data_set.category).to eq("FundAdjustment")
      expect(data_set.data).to eq("Files processed: spec/fixtures/peoplesoft_2/test_alma_1.csv;  Error processing: None")
      expect(data_set.report_time).to eq(Time.zone.now.midnight)
      expect(File.exist?('spec/fixtures/peoplesoft_2/test_alma_1.csv.processed')).to be_truthy
      expect(File.exist?('spec/fixtures/ephemeral_2/test_alma_1.csv')).to be_truthy
    end

    it "transfers multiple files" do
      allow(sftp_session).to receive(:upload!).twice
      FileUtils.cp(Rails.root.join('spec', 'fixtures', 'fund_transactions-2012-07-19-09-09-00.csv'), 'spec/fixtures/peoplesoft_2/test_alma_1.csv')
      FileUtils.cp(Rails.root.join('spec', 'fixtures', 'fund_transactions-2012-07-19-09-09-00.csv'), 'spec/fixtures/peoplesoft_2/test_alma_2.csv')

      expect { expect(fund_adjustment.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
      expect(sftp_session).to have_received(:upload!).with("spec/fixtures/ephemeral_2/test_alma_1.csv", '/alma/fund_adjustment/test_alma_1.csv')
      expect(sftp_session).to have_received(:upload!).with("spec/fixtures/ephemeral_2/test_alma_2.csv", '/alma/fund_adjustment/test_alma_2.csv')
      data_set = DataSet.last
      expect(data_set.category).to eq("FundAdjustment")
      expect(data_set.data).to eq("Files processed: spec/fixtures/peoplesoft_2/test_alma_1.csv, spec/fixtures/peoplesoft_2/test_alma_2.csv;  Error processing: None")
      expect(data_set.report_time).to eq(Time.zone.now.midnight)
      expect(File.exist?('spec/fixtures/peoplesoft_2/test_alma_1.csv.processed')).to be_truthy
      expect(File.exist?('spec/fixtures/peoplesoft_2/test_alma_2.csv.processed')).to be_truthy
      expect(File.exist?('spec/fixtures/ephemeral_2/test_alma_1.csv')).to be_truthy
      expect(File.exist?('spec/fixtures/ephemeral_2/test_alma_2.csv')).to be_truthy
    end

    context "handles an ftp error" do
      it "notes the error" do
        allow(sftp_session).to receive(:upload!).and_raise(Net::SFTP::StatusException, Net::SFTP::Response.new({}, { code: 500 }))
        FileUtils.cp(Rails.root.join('spec', 'fixtures', 'fund_transactions-2012-07-19-09-09-00.csv'), 'spec/fixtures/peoplesoft_2/test_alma_1.csv')

        expect { expect(fund_adjustment.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
        expect(sftp_session).to have_received(:upload!).with("spec/fixtures/ephemeral_2/test_alma_1.csv", '/alma/fund_adjustment/test_alma_1.csv')
        data_set = DataSet.last
        expect(data_set.category).to eq("FundAdjustment")
        expect(data_set.data).to eq("Files processed: None;  Error processing: spec/fixtures/peoplesoft_2/test_alma_1.csv")
        expect(data_set.report_time).to eq(Time.zone.now.midnight)
        expect(File.exist?('spec/fixtures/ephemeral_2/test_alma_1.csv.processed')).not_to be_truthy
        expect(File.exist?('spec/fixtures/peoplesoft_2/test_alma_1.csv')).to be_truthy
        expect(File.exist?('spec/fixtures/ephemeral_2/test_alma_1.csv')).to be_truthy
      end
    end

    context "file with no data" do
      it "notes that nothing was processed" do
        FileUtils.touch('spec/fixtures/peoplesoft_2/test_alma_1.csv')

        expect { expect(fund_adjustment.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
        data_set = DataSet.last
        expect(data_set.category).to eq("FundAdjustment")
        expect(data_set.data).to eq("Files processed: spec/fixtures/peoplesoft_2/test_alma_1.csv;  Error processing: None")
        expect(data_set.report_time).to eq(Time.zone.now.midnight)
        expect(File.exist?('spec/fixtures/peoplesoft_2/test_alma_1.csv.processed')).to eq true
      end
    end

    context "file with only headers" do
      it "notes that nothing was processed" do
        FileUtils.cp(Rails.root.join('spec', 'fixtures', 'fund_transactions_empty.csv'), 'spec/fixtures/peoplesoft_2/test_alma_1.csv')

        expect { expect(fund_adjustment.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
        data_set = DataSet.last
        expect(data_set.category).to eq("FundAdjustment")
        expect(data_set.data).to eq("Files processed: spec/fixtures/peoplesoft_2/test_alma_1.csv;  Error processing: None")
        expect(data_set.report_time).to eq(Time.zone.now.midnight)
        expect(File.exist?('spec/fixtures/peoplesoft_2/test_alma_1.csv.processed')).to eq true
      end
    end

    context "file with incorrect headers" do
      it "throws an error" do
        FileUtils.cp(Rails.root.join('spec', 'fixtures', 'fund_transactions_invalid_headers.csv'), 'spec/fixtures/peoplesoft_2/test_alma_1.csv')

        expect { expect(fund_adjustment.run) }.to raise_error(CSVValidator::InvalidHeadersError)
      end
    end

    context "no files" do
      it "notes that nothing was processed" do
        allow(sftp_session).to receive(:upload!)

        expect { expect(fund_adjustment.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
        expect(sftp_session).not_to have_received(:upload!)
        data_set = DataSet.last
        expect(data_set.category).to eq("FundAdjustment")
        expect(data_set.data).to eq("Files processed: None;  Error processing: None")
        expect(data_set.report_time).to eq(Time.zone.now.midnight)
        expect(File.exist?('spec/fixtures/peoplesoft_2/test_alma_1.csv.processed')).to eq false

        expect(File.exist?('spec/fixtures/ephemeral_2/test_alma_1.csv.processed')).to eq false
      end
    end
  end
end
