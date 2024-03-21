# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Gobi::IsbnReportJob, type: :model do
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

  it 'creates a tsv for uploading to gobi' do
    expect(File.exist?(new_tsv_path)).to be false
    isbn_job.run
    expect(File.exist?(new_tsv_path)).to be true
    lines = File.open(new_tsv_path).to_a
    expect(lines[0]).to include("isbn\tcode_string\taccount_code\n")
    expect(lines[1]).to include("9789775414656\t")
  end

  it 'uploads the relevant files' do
    expect(isbn_job.run).to be_truthy
    expect(sftp_session).to have_received(:upload!).with(new_tsv_path, '/holdings/2024-03-16-gobi-isbn-updates.tsv').once
  end
end
