# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ReportDownloader, type: :model do
  let(:downloader) do
    described_class.new(
                        sftp: AlmaSftp.new,
                        file_pattern: 'received_items_published_last_5_years_\d{12}.csv',
                        input_sftp_base_dir: '/alma/isbns'
                      )
  end

  it 'has an sftp object associated with it' do
    expect(downloader.sftp).to be_an_instance_of(AlmaSftp)
  end

  it 'has a file pattern to match based on' do
    expect(downloader.file_pattern).to be_an_instance_of(String)
    expect(downloader.file_pattern).to eq('received_items_published_last_5_years_\d{12}.csv')
  end

  it 'has a directory to look in' do
    expect(downloader.input_sftp_base_dir).to be_an_instance_of(String)
    expect(downloader.input_sftp_base_dir).to eq('/alma/isbns')
  end

  describe '#download' do
    include_context 'sftp_gobi_isbn'

    it 'downloads matching files' do
      temp_files = downloader.download
      expect(sftp_session).to have_received(:download!).with(file_full_path_one, temp_file_one)
      expect(sftp_session).to have_received(:download!).with(file_full_path_two, temp_file_two)
      expect(temp_files).to be_an_instance_of(Array)
      expect(temp_files.size).to eq(2)
      expect(temp_files.first).to be_an_instance_of(String)
      expect(File.exist?(temp_files.first)).to be true
    end
  end
end
