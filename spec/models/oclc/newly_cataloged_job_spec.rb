# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Oclc::NewlyCatalogedJob, type: :model do
  subject(:newly_cataloged_job) { described_class.new }

  let(:file_full_path) { "#{input_sftp_base_dir}#{file_name_to_download}" }
  let(:input_sftp_base_dir) { '/xfer/metacoll/out/ongoing/new/' }
  let(:file_name_to_download) { 'metacoll.PUL.new.D20230706.T213019.MZallDLC.1.mrc' }
  let(:temp_file) { Tempfile.new(encoding: 'ascii-8bit') }
  let(:sftp_entry1) { instance_double("Net::SFTP::Protocol::V01::Name", name: file_name_to_download) }
  let(:sftp_entry2) { instance_double("Net::SFTP::Protocol::V01::Name", name: "metacoll.PUL.new.D20230709.T213017.MZallDLC.1.mrc.processed") }
  let(:sftp_entry3) { instance_double("Net::SFTP::Protocol::V01::Name", name: "metacoll.PUL.new.D20230705.T213018.allpcc.1.mrc") }
  let(:sftp_session) { instance_double("Net::SFTP::Session", dir: sftp_dir) }
  let(:sftp_dir) { instance_double("Net::SFTP::Operations::Dir") }

  before do
    allow(Tempfile).to receive(:new).and_return(temp_file)
    allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry1).and_yield(sftp_entry2).and_yield(sftp_entry3)
    allow(sftp_session).to receive(:download!).with(file_full_path, temp_file).and_return(Rails.root.join('spec', 'fixtures', 'oclc', file_name_to_download).to_s)
    allow(Net::SFTP).to receive(:start).and_yield(sftp_session)
  end
  it 'downloads only the relevant files' do
    expect(newly_cataloged_job.run).to be_truthy
    expect(sftp_session).to have_received(:download!).with(file_full_path, temp_file)
  end
end
