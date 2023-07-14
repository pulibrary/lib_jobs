# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaSubmitCollection::AlmaSubmitCollectionJob, type: :model do
  describe "#run" do
    let(:alma_recap_filename) { 'incremental_recap_25908087650006421_20230420_160408[057]_new.xml.tar.gz' }
    let(:file_name) { instance_double("Net::SFTP::Protocol::V01::Name", name: alma_recap_filename) }
    let(:file_attributes) { instance_double("Net::SFTP::Protocol::V01::Attributes") }
    let(:sftp_session) { instance_double("Net::SFTP::Session", dir: sftp_dir) }
    let(:sftp_dir) { instance_double("Net::SFTP::Operations::Dir") }
    let(:sftp_file_factory) { Net::SFTP::Operations::FileFactory.new(sftp_session) }
    let(:file_size) { 1028 }

    before do
      allow(file_attributes).to receive(:size).and_return file_size
      allow(file_name).to receive(:attributes).and_return file_attributes
      allow(sftp_dir).to receive(:foreach).and_yield file_name
      allow(sftp_session).to receive(:file).and_return sftp_file_factory
      allow(sftp_session).to receive(:rename)
      allow(sftp_file_factory).to receive(:open).and_return File.new(Pathname.new(file_fixture_path).join("alma", alma_recap_filename))
      allow(Net::SFTP).to receive(:start).and_yield sftp_session
    end

    it "runs" do
      described_class.new(category: 'mouse').run
    end

    it "logs the number of records processed" do
      described_class.new(category: 'mouse').run
      data_last = DataSet.last
      expect(data_last.data).to eq "7 records processed."
    end
  end
end
