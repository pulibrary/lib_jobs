# frozen_string_literal: true
require "rails_helper"

RSpec.describe NewlyCatalogedMailer, type: :mailer do
  describe "#report" do
    let(:first_selector_config) { Rails.application.config.newly_cataloged.selectors[0] }
    let(:selector) { Oclc::Selector.new(selector_config: first_selector_config) }
    let(:file_path) { 'spec/fixtures/oclc/example_csv_for_selector.csv' }
    let(:mail) { described_class.report(selector:, file_path:) }
    let(:freeze_time) { Time.utc(2023, 7, 13) }

    around do |example|
      Timecop.freeze(freeze_time) do
        example.run
      end
    end

    it "renders the headers" do
      expect(mail.subject).to eq("LC Slips for the week of July 13, 2023")
      expect(mail.to).to eq(['bordelon@princeton.edu'])
      expect(mail.cc).to eq(['pdiskin@princeton.edu'])
      expect(mail.from).to eq(["lib-jobs@princeton.edu"])
      expect(mail.attachments.first.filename).to eq('example_csv_for_selector.csv')
    end
  end
end
