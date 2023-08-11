# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaPodRecords::AlmaPodFileList, type: :model do
  include_context 'sftp'

  subject(:alma_pod_file_list) { described_class.new }

  let(:name) { 'file.tar.gz' }
  let(:mtime) { Time.now.to_i }
  let(:file_name) { instance_double("Net::SFTP::Protocol::V01::Name", name:) }
  let(:file_attributes) { instance_double("Net::SFTP::Protocol::V01::Attributes") }
  let(:file_size) { 1028 }

  before do
    allow(file_attributes).to receive(:size).and_return file_size
    allow(file_attributes).to receive(:mtime).and_return mtime
    allow(file_name).to receive(:attributes).and_return file_attributes
    allow(sftp_dir).to receive(:foreach).and_yield file_name
    allow(sftp_session).to receive(:file).and_return StringIO
  end

  describe 'if the file is valid' do
    it "downloads the file" do
      expect(alma_pod_file_list.files.count).to eq(1)
    end
  end

  describe "if the filename doesn't match the pattern" do
    let(:name) { 'BAD' }
    it "doesn't download the file" do
      expect(alma_pod_file_list.files).to be_empty
    end
  end

  describe 'if the file is empty' do
    let(:file_size) { 0 }
    it "doesn't download the file" do
      expect(alma_pod_file_list.files).to be_empty
    end
  end

  describe 'if the file is old' do
    let(:mtime) { Time.new(1980).to_i }
    it "doesn't download the file" do
      expect(alma_pod_file_list.files).to be_empty
    end
  end
end
