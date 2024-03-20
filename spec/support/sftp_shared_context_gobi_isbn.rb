# frozen_string_literal: true

RSpec.shared_context 'sftp_gobi_isbn' do
  include_context 'sftp'
  include_context 'gobi_isbn'

  let(:input_sftp_base_dir) { '/alma/isbns' }
  let(:file_full_path_one) { "#{input_sftp_base_dir}/#{file_name_to_download_one}" }
  let(:file_name_to_download_two) { 'received_items_published_last_5_years_202403040620.csv' }
  let(:file_full_path_two) { "#{input_sftp_base_dir}/#{file_name_to_download_two}" }
  let(:temp_file_two) { Tempfile.new(encoding: 'ascii-8bit') }
  let(:sftp_entry1) { instance_double("Net::SFTP::Protocol::V01::Name", name: file_name_to_download_one) }
  let(:sftp_entry2) { instance_double("Net::SFTP::Protocol::V01::Name", name: file_name_to_download_two) }
  let(:sftp_entry3) { instance_double("Net::SFTP::Protocol::V01::Name", name: 'accidental upload') }

  before do
    allow(Tempfile).to receive(:new).and_return(temp_file_one, temp_file_two)
    allow(sftp_session).to receive(:download!).with(file_full_path_one, temp_file_one)
    allow(sftp_session).to receive(:download!).with(file_full_path_two, temp_file_two)
    allow(sftp_session).to receive(:upload!).with(new_tsv_path, '/holdings/2024-03-16-gobi-isbn-updates.tsv')
    allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry1).and_yield(sftp_entry2).and_yield(sftp_entry3)
  end
end
