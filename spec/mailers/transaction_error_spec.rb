# frozen_string_literal: true
require "rails_helper"

RSpec.describe TransactionErrorMailer, type: :mailer do
  let(:mail) { described_class.report(duplicate_ids: ['']) }

  before do
    # Mock environment variables for emails
    allow(ENV).to receive(:fetch).with('TRANSACTION_ERROR_FEED_RECIPIENTS', "test_user@princeton.edu")
                                 .and_return('person_4@princeton.edu,person_5@princeton.edu,person_6@princeton.edu')
    # Not used in this test, but needed to load config file successfully
    allow(ENV).to receive(:fetch).with('VOUCHER_FEED_RECIPIENTS', "test_user@princeton.edu")
                                 .and_return('person_1@princeton.edu,person_2@princeton.edu,person_3@princeton.edu')
    allow(ENV).to receive(:fetch).with('PEOPLESOFT_BURSAR_RECIPIENTS', "test_user@princeton.edu")
                                 .and_return('person_1@princeton.edu,person_2@princeton.edu')
    allow(ENV).to receive(:fetch).with('PEOPLESOFT_BURSAR_NO_REPORT_RECIPIENTS', "test_user@princeton.edu")
                                 .and_return('person_1@princeton.edu,person_2@princeton.edu')
    allow(ENV).to receive(:fetch).with('PEOPLE_ERROR_NOTIFICATION_RECIPIENTS', "test_user@princeton.edu")
                                 .and_return('person_1@princeton.edu,person_2@princeton.edu')
  end

  it "renders the headers" do
    expect(mail.subject).to eq("PeopleSoft Duplicate Transactions")
    expect(mail.to).to eq(["person_4@princeton.edu", "person_5@princeton.edu", "person_6@princeton.edu"])
    expect(mail.from).to eq(["lib-jobs@princeton.edu"])
  end
end
