# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaPodRecords::AlmaPodJob, type: :model do
  let(:filenames) { ['filename'] }
  let(:tarball_contents) { [StringIO.new('<collection/>')] }
  let(:list) { instance_double("AlmaPodRecords::AlmaPodFileList") }

  before do
    allow(list).to receive(:files).and_return filenames
    allow(list).to receive(:download_and_decompress_file).and_return(tarball_contents)
  end
  it 'sends each file to the POD' do
    pod_url = 'https://pod.stanford.edu/organizations/princeton/uploads'
    stub_request(:post, pod_url)
      .to_return(status: 201, body: '{"url":"my-url"}')
    described_class.new(incoming_file_list: list, directory: Rails.root.join('tmp')).send_files
    expect(a_request(:post, pod_url)).to have_been_made
  end
end
