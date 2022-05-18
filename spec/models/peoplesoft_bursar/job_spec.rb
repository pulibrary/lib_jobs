# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PeoplesoftBursar::Job, type: :model do
  let(:job) { described_class.new(output_base_dir: '/tmp', report: report) }

  describe "#run" do
    context 'with a credit report' do
      let(:report) { PeoplesoftBursar::CreditReport.new(list: [FactoryBot.build(:credit)]) }

      it "generates an output file" do
        expect { expect(job.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(1)
        data_set = DataSet.last
        expect(data_set.category).to eq("BursarReport")
        expect(data_set.data).to eq("Type: Payment\nNumber of lines: 1\nTotal: -000000000005.50")
        expect(data_set.report_time.to_date).to eq(Time.zone.now.to_date)
        data = File.read("/tmp/libfines.dat")
        expect(data).to eq(report.to_s)
        File.delete("/tmp/libfines.dat")
        confirm_email = ActionMailer::Base.deliveries.last
        expect(confirm_email.subject).to eq("Library Credit Feed")
        expect(confirm_email.html_part.body.to_s).to include("Number of lines: 1")
        expect(confirm_email.html_part.body.to_s).not_to include("No file to send")
      end

      context "no items" do
        let(:report) { PeoplesoftBursar::CreditReport.new(list: []) }

        it "does not generates an output file if no invoices are present" do
          expect { expect(job.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(1)
          expect(File.exist?("/tmp/libfines.dat")).to be_falsey
          confirm_email = ActionMailer::Base.deliveries.last
          expect(confirm_email.subject).to eq("Library Credit Feed")
          expect(confirm_email.html_part.body.to_s).not_to include("Number of lines: ")
          expect(confirm_email.html_part.body.to_s).to include("No file to send")
        end
      end
    end

    context 'with a fine report' do
      let(:report) { PeoplesoftBursar::FineReport.new(list: [FactoryBot.build(:fine)]) }

      it 'generates an output file' do
        expect { expect(job.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(1)
        data_set = DataSet.last
        expect(data_set.category).to eq("BursarReport")
        expect(data_set.data).to eq("Type: Payment\nNumber of lines: 1\nTotal: 0000000000005.50")
        expect(data_set.report_time.to_date).to eq(Time.zone.now.to_date)
        data = File.read("/tmp/libfines.dat")
        expect(data).to eq(report.to_s)
        File.delete("/tmp/libfines.dat")
        confirm_email = ActionMailer::Base.deliveries.last
        expect(confirm_email.subject).to eq("Library Fine Feed")
        expect(confirm_email.html_part.body.to_s).to include("Number of lines: 1")
        expect(confirm_email.html_part.body.to_s).not_to include("No file to send")
      end
    end
  end
end
