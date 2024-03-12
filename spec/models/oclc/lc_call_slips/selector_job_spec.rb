# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Oclc::LcCallSlips::SelectorJob, type: :model, newly_cataloged: true do
  include_context 'sftp_newly_cataloged'

  subject(:newly_cataloged_job) { described_class.new }

  let(:new_csv_path_1) { Rails.root.join('spec', 'fixtures', 'oclc', '2023-07-12-newly-cataloged-by-lc-bordelon.csv') }
  let(:new_csv_path_2) { Rails.root.join('spec', 'fixtures', 'oclc', '2023-07-12-newly-cataloged-by-lc-darrington.csv') }

  around do |example|
    File.delete(new_csv_path_1) if File.exist?(new_csv_path_1)
    File.delete(new_csv_path_2) if File.exist?(new_csv_path_2)
    example.run
    File.delete(new_csv_path_1) if File.exist?(new_csv_path_1)
    File.delete(new_csv_path_2) if File.exist?(new_csv_path_2)
  end

  before do
    allow(Tempfile).to receive(:new).and_return(temp_file_one, temp_file_two)
    allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry1).and_yield(sftp_entry2).and_yield(sftp_entry3).and_yield(sftp_entry4)
    allow(sftp_session).to receive(:download!).with(file_full_path_one, temp_file_one)
    allow(sftp_session).to receive(:download!).with(file_full_path_two, temp_file_two)
  end

  it 'downloads only the relevant files' do
    expect(newly_cataloged_job.run).to be_truthy
    expect(sftp_session).to have_received(:download!).with(file_full_path_one, temp_file_one)
    expect(sftp_session).to have_received(:download!).with(file_full_path_two, temp_file_two)
  end

  it 'creates a csv file for each selector' do
    expect(File.exist?(new_csv_path_1)).to be false
    expect(File.exist?(new_csv_path_2)).to be false
    newly_cataloged_job.run
    expect(File.exist?(new_csv_path_1)).to be true
    expect(File.exist?(new_csv_path_2)).to be true
  end

  it 'records data to display in the UI' do
    newly_cataloged_job.run
    data_set = DataSet.last
    expect(data_set.report_time).to eq(freeze_time)
    expect(data_set.data).to eq("Files created and emailed to selectors: spec/fixtures/oclc/2023-07-12-newly-cataloged-by-lc-bordelon.csv," \
      " spec/fixtures/oclc/2023-07-12-newly-cataloged-by-lc-darrington.csv")
  end

  it 'puts data in the csv file for each selector' do
    newly_cataloged_job.run
    csv_file_one = CSV.read(new_csv_path_1)
    expect(csv_file_one.length).to eq(25)
    csv_file_two = CSV.read(new_csv_path_2)
    expect(csv_file_two.length).to eq(38)
  end

  it 'emails the csv to the selectors' do
    expect(NewlyCatalogedMailer).to receive(:report).twice.and_call_original
    newly_cataloged_job.run
  end
end
