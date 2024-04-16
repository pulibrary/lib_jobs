# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Gobi::IsbnReportJob, type: :model, file_download: true do
  include_context 'sftp_gobi_isbn'
  let(:isbn_job) { described_class.new }

  it_behaves_like 'a lib job'

  it 'has a report downloader' do
    expect(isbn_job.report_downloader).to be_an_instance_of(ReportDownloader)
  end

  it 'downloads the relevant files' do
    expect(isbn_job.run).to be_truthy
    expect(sftp_session).to have_received(:download!).with(file_full_path_one, temp_file_one)
    expect(sftp_session).to have_received(:download!).with(file_full_path_two, temp_file_two)
  end

  it 'renames the relevant files to .processed once the job has completed successfully' do
    allow(sftp_session).to receive(:rename)
    isbn_job.run
    expect(sftp_session).to have_received(:rename).with(file_full_path_one, "#{file_full_path_one}.processed")
    expect(sftp_session).to have_received(:rename).with(file_full_path_two, "#{file_full_path_two}.processed")
  end

  it 'creates a csv for uploading to gobi' do
    expect(File.exist?(new_csv_path)).to be false
    isbn_job.run
    expect(File.exist?(new_csv_path)).to be true
    lines = File.open(new_csv_path).to_a
    expect(lines[0]).to include("9789775414656|")
  end

  it 'uploads the relevant files' do
    expect(isbn_job.run).to be_truthy
    expect(sftp_session).to have_received(:upload!).with(new_csv_path, '/holdings/2024-03-16-gobi-isbn-updates.txt').once
  end

  it 'adds a count of ISBNs sent to the dataset' do
    isbn_job.run
    data_set = DataSet.last
    expect(data_set.data).to be
  end
end
