# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaFundAdjustment::AdjustmentCheck, type: :model do
  subject(:adjustment_check) { described_class.new(peoplesoft_input_base_dir: '/tmp', peoplesoft_input_file_pattern: 'test_alma*.csv') }

  describe "#run" do
    after do
      File.delete("/tmp/test_alma_1.csv") if File.exist?("/tmp/test_alma_1.csv")
      File.delete("/tmp/test_alma_2.csv") if File.exist?("/tmp/test_alma_2.csv")
      File.delete("/tmp/test_alma_1.csv.processed") if File.exist?("/tmp/test_alma_1.csv.processed")
      File.delete("/tmp/test_alma_2.csv.processed") if File.exist?("/tmp/test_alma_2.csv.processed")
    end

    it "validates non processed ids" do
      FileUtils.cp(Rails.root.join('spec', 'fixtures', 'fund_transactions-2012-07-19-09-09-00.csv'), '/tmp/test_alma_1.csv')

      expect { expect(adjustment_check.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(0)
                                                                                                            .and change { PeoplesoftTransaction.count }.by(1)
      expect(PeoplesoftTransaction.last.transaction_id).to eq("123456-Online Entry | A Fund We have | 07/14/2021")
      expect(File.exist?('/tmp/test_alma_1.csv')).to be_truthy
    end

    it "errors for an already processed id" do
      FileUtils.cp(Rails.root.join('spec', 'fixtures', 'fund_transactions-2012-07-19-09-09-00.csv'), '/tmp/test_alma_1.csv')
      PeoplesoftTransaction.create(transaction_id: "123456-Online Entry | A Fund We have | 07/14/2021")

      expect { expect(adjustment_check.run).to be_falsey }.to change { ActionMailer::Base.deliveries.count }.by(1)
                                                                                                            .and change { PeoplesoftTransaction.count }.by(0)
      expect(File.exist?('/tmp/test_alma_1.csv.error')).to be_truthy
      error_email = ActionMailer::Base.deliveries.last
      expect(error_email.subject).to eq("PeopleSoft Duplicate Transactions")
      expect(error_email.html_part.body.to_s).to include("Duplicate Transactions from Peoplesoft were Encountered")
      expect(error_email.html_part.body.to_s).to include("123456")
    end

    context "with a file with only headers" do
      it "passes the file to the next step" do
        FileUtils.cp(Rails.root.join('spec', 'fixtures', 'fund_transactions_empty.csv'), '/tmp/test_alma_1.csv')

        expect { expect(adjustment_check.run).to be_truthy }
      end
    end
    context "with a file with invalid headers" do
      it "throws an error" do
        FileUtils.cp(Rails.root.join('spec', 'fixtures', 'fund_transactions_invalid_headers.csv'), '/tmp/test_alma_1.csv')

        expect { adjustment_check.run }.to raise_error(CSVValidator::InvalidHeadersError)
      end
    end
    context "job is turned off" do
      before do
        allow(Flipflop).to receive(:alma_fund_adjustment?).and_return(false)
      end
      it "does not run" do
        FileUtils.cp(Rails.root.join('spec', 'fixtures', 'fund_transactions_empty.csv'), '/tmp/test_alma_1.csv')
        expect(adjustment_check.run).to be false
      end
      it "logs that it is turned off" do
        FileUtils.cp(Rails.root.join('spec', 'fixtures', 'fund_transactions_empty.csv'), '/tmp/test_alma_1.csv')
        adjustment_check.run
        data_set = DataSet.last
        expect(data_set.data).to eq("Alma Fund Adjustment job is typically scheduled for this time, but it is turned off.  Go to /features to turn it back on.")
      end
    end
  end
end
