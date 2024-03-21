# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ReportDownloader, type: :model do
  let(:downloader) do
    described_class.new(
                        sftp: AlmaSftp.new,
                        file_pattern: 'received_items_published_last_5_years_\d{12}.csv',
                        input_sftp_base_dir: '/alma/isbns',
                        process_class: Gobi::IsbnFile
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

  describe '#run' do
    include_context 'sftp_gobi_isbn'

    it 'downloads matching files' do
      working_file_names = downloader.run
      expect(sftp_session).to have_received(:download!).with(file_full_path_one, temp_file_one)
      expect(sftp_session).to have_received(:download!).with(file_full_path_two, temp_file_two)
      expect(working_file_names).to be_an_instance_of(Array)
      expect(working_file_names.size).to eq(2)
      expect(working_file_names.first).to be_an_instance_of(String)
      expect(File.exist?(File.join('spec', 'fixtures', 'gobi', working_file_names.first))).to be true
    end
  end
end
