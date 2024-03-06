# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Oclc::NewlyCatalogedJob, type: :model do
  include_context 'sftp'

  subject(:newly_cataloged_job) { described_class.new }

  let(:file_full_path_one) { "#{input_sftp_base_dir}#{file_name_to_download_one}" }
  let(:file_full_path_two) { "#{input_sftp_base_dir}#{file_name_to_download_two}" }
  let(:input_sftp_base_dir) { '/xfer/metacoll/out/ongoing/new/' }
  let(:oclc_fixture_file_path_one) { Rails.root.join('spec', 'fixtures', 'oclc', file_name_to_download_one) }
  let(:oclc_fixture_file_path_two) { Rails.root.join('spec', 'fixtures', 'oclc', file_name_to_download_two) }
  let(:file_name_to_download_one) { 'metacoll.PUL.new.D20230706.T213019.MZallDLC.1.mrc' }
  let(:file_name_to_download_two) { 'metacoll.PUL.new.D20230718.T213016.MZallDLC.1.mrc' }
  let(:temp_file_one) { Tempfile.new(encoding: 'ascii-8bit') }
  let(:temp_file_two) { Tempfile.new(encoding: 'ascii-8bit') }
  let(:sftp_entry1) { instance_double("Net::SFTP::Protocol::V01::Name", name: file_name_to_download_one) }
  let(:sftp_entry2) { instance_double("Net::SFTP::Protocol::V01::Name", name: "metacoll.PUL.new.D20230709.T213017.MZallDLC.1.mrc.processed") }
  let(:sftp_entry3) { instance_double("Net::SFTP::Protocol::V01::Name", name: "metacoll.PUL.new.D20230705.T213018.allpcc.1.mrc") }
  let(:sftp_entry4) { instance_double("Net::SFTP::Protocol::V01::Name", name: file_name_to_download_two) }
  let(:freeze_time) { Time.utc(2023, 7, 12) }
  let(:new_csv_path_1) { Rails.root.join('spec', 'fixtures', 'oclc', '2023-07-12-newly-cataloged-by-lc-bordelon.csv') }
  let(:new_csv_path_2) { Rails.root.join('spec', 'fixtures', 'oclc', '2023-07-12-newly-cataloged-by-lc-darrington.csv') }
  let(:new_csv_path_3) { Rails.root.join('spec', 'fixtures', 'oclc', '2023-07-12-newly-cataloged-by-lc-donatiello.csv') }

  around do |example|
    File.delete(new_csv_path_1) if File.exist?(new_csv_path_1)
    File.delete(new_csv_path_2) if File.exist?(new_csv_path_2)
    File.delete(new_csv_path_3) if File.exist?(new_csv_path_3)
    temp_file_one.write(File.open(oclc_fixture_file_path_one).read)
    temp_file_two.write(File.open(oclc_fixture_file_path_two).read)
    Timecop.freeze(freeze_time) do
      example.run
    end
    File.delete(new_csv_path_1) if File.exist?(new_csv_path_1)
    File.delete(new_csv_path_2) if File.exist?(new_csv_path_2)
    File.delete(new_csv_path_3) if File.exist?(new_csv_path_3)
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
      " spec/fixtures/oclc/2023-07-12-newly-cataloged-by-lc-darrington.csv, spec/fixtures/oclc/2023-07-12-newly-cataloged-by-lc-donatiello.csv")
  end

  it 'puts data in the csv file for each selector' do
    newly_cataloged_job.run
    csv_file_one = CSV.read(new_csv_path_1)
    expect(csv_file_one.length).to eq(25)
    csv_file_two = CSV.read(new_csv_path_2)
    expect(csv_file_two.length).to eq(38)
  end

  it 'emails the csv to the selectors' do
    expect(NewlyCatalogedMailer).to receive(:report).exactly(3).times.and_call_original
    newly_cataloged_job.run
  end
end
