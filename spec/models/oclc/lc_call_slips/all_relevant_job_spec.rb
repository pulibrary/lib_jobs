# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Oclc::LcCallSlips::AllRelevantJob, type: :model, lc_call_slips: true, file_download: true do
  include_context 'sftp_newly_cataloged'

  subject(:newly_cataloged_job_all) { described_class.new }
  let(:new_csv_path) { Rails.root.join('spec', 'fixtures', 'oclc', '2023-07-12-newly-cataloged-by-lc-all.csv') }

  around do |example|
    File.delete(new_csv_path) if File.exist?(new_csv_path)
    example.run
    File.delete(new_csv_path) if File.exist?(new_csv_path)
  end

  it_behaves_like 'a lib job'

  it 'creates a csv' do
    expect(File.exist?(new_csv_path)).to be false
    subject.run
    expect(File.exist?(new_csv_path)).to be true
    csv_file = CSV.read(new_csv_path)
    expect(csv_file.length).to eq(1152)
  end
end
