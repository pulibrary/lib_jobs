# frozen_string_literal: true

RSpec.shared_context 'sftp_newly_cataloged' do
  let(:sftp_session) { instance_double("Net::SFTP::Session", dir: sftp_dir) }
  let(:sftp_dir) { instance_double("Net::SFTP::Operations::Dir") }
  let(:input_sftp_base_dir) { '/xfer/metacoll/out/ongoing/new/' }
  let(:sftp_entry1) { instance_double("Net::SFTP::Protocol::V01::Name", name: file_name_to_download_one) }
  let(:sftp_entry2) { instance_double("Net::SFTP::Protocol::V01::Name", name: "metacoll.PUL.new.D20230709.T213017.MZallDLC.1.mrc.processed") }
  let(:sftp_entry3) { instance_double("Net::SFTP::Protocol::V01::Name", name: "metacoll.PUL.new.D20230705.T213018.allpcc.1.mrc") }
  let(:sftp_entry4) { instance_double("Net::SFTP::Protocol::V01::Name", name: file_name_to_download_two) }
  let(:file_name_to_download_one) { 'metacoll.PUL.new.D20230706.T213019.MZallDLC.1.mrc' }
  let(:file_name_to_download_two) { 'metacoll.PUL.new.D20230718.T213016.MZallDLC.1.mrc' }
  let(:file_full_path_one) { "#{input_sftp_base_dir}#{file_name_to_download_one}" }
  let(:file_full_path_two) { "#{input_sftp_base_dir}#{file_name_to_download_two}" }
  let(:temp_file_one) { Tempfile.new(encoding: 'ascii-8bit') }
  let(:temp_file_two) { Tempfile.new(encoding: 'ascii-8bit') }
  let(:freeze_time) { Time.utc(2023, 7, 12) }
  let(:oclc_fixture_file_path_one) { Rails.root.join('spec', 'fixtures', 'oclc', file_name_to_download_one) }
  let(:oclc_fixture_file_path_two) { Rails.root.join('spec', 'fixtures', 'oclc', file_name_to_download_two) }

  before do
    allow(Tempfile).to receive(:new).and_return(temp_file_one, temp_file_two)
    allow(Net::SFTP).to receive(:start).and_yield(sftp_session)
    allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry1).and_yield(sftp_entry2).and_yield(sftp_entry3).and_yield(sftp_entry4)
    allow(sftp_session).to receive(:download!).with(file_full_path_one, temp_file_one)
    allow(sftp_session).to receive(:download!).with(file_full_path_two, temp_file_two)
  end

  around do |example|
    temp_file_one.write(File.open(oclc_fixture_file_path_one).read)
    temp_file_two.write(File.open(oclc_fixture_file_path_two).read)
    Timecop.freeze(freeze_time) do
      example.run
    end
  end
end
