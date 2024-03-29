# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaPodRecords::AlmaPodJob, type: :model do
  let(:filenames) { ['filename'] }
  let(:tarball_contents) { [StringIO.new('<collection/>')] }
  let(:list) { instance_double("AlmaPodRecords::AlmaPodFileList") }
  let(:pod_url) { 'https://pod.stanford.edu/organizations/princeton/uploads' }
  let(:directory) { Rails.root.join('tmp') }

  before do
    allow(list).to receive(:files).and_return filenames
    allow(list).to receive(:download_and_decompress_file).and_return(tarball_contents)
    stub_request(:post, pod_url)
      .to_return(status: 201, body: '{"url":"my-url"}')
  end

  context 'sending a compressed file' do
    it 'sends a compressed file to the POD' do
      orig_num_gz_files = Dir["#{directory}/*.gz"].length
      described_class.new(incoming_file_list: list, directory:).send_files
      new_num_gz_files = Dir["#{directory}/*.gz"].length
      expect(new_num_gz_files - orig_num_gz_files).to eq(1)
    end
  end

  describe 'writing files' do
    let(:file_path) { Pathname.new(Rails.root.join('tmp', "test_file.xml")) }
    let(:alma_pod_job) { described_class.new(incoming_file_list: list, directory: Rails.root.join('tmp')) }

    context 'writing compressed files' do
      let(:zipped_file_path) { Pathname.new(Rails.root.join('tmp', "test_file.xml.gz")) }
      let(:alma_pod_job) { described_class.new(incoming_file_list: list, directory: Rails.root.join('tmp')) }

      around do |example|
        File.delete(file_path) if File.exist?(file_path)
        File.delete(zipped_file_path) if File.exist?(zipped_file_path)
        example.run
        File.delete(file_path) if File.exist?(file_path)
        File.delete(zipped_file_path) if File.exist?(zipped_file_path)
      end

      it 'writes new gz files' do
        expect(File.exist?(file_path)).to be false
        expect(File.exist?(zipped_file_path)).to be false
        alma_pod_job.write_file(file_path: zipped_file_path, contents: tarball_contents.first)
        expect(File.exist?(file_path)).to be false
        expect(File.exist?(zipped_file_path)).to be true
        expect(File.extname(zipped_file_path)).to eq('.gz')
        `gunzip #{zipped_file_path}`
        expect(File.read(file_path)).to eq("<?xml version=\"1.0\"?>\n<collection xmlns=\"http://www.loc.gov/MARC21/slim\"></collection>")
      end
    end
  end
end
