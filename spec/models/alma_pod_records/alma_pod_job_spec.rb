# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaPodRecords::AlmaPodJob, type: :model do
  it 'sends each file to the POD' do
    pod_url = 'https://pod.stanford.edu/organizations/princeton/uploads'
    stub_request(:post, pod_url)
      .to_return(status: 201, body: '{"url":"my-url"}')
    documents = Array.new(5) { StringIO.new('<collection/>') }
    list = AlmaPodRecords::AlmaPodFileList.new(documents: documents)
    described_class.new(incoming_file_list: list, directory: Rails.root.join('tmp')).send_files
    expect(a_request(:post, pod_url)).to have_been_made.times(5)
  end
end
