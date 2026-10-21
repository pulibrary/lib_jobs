# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'oclc_sftp provider', type: :model do
  subject(:oclc_sftp) { Shared::Slice['oclc_sftp'] }

  include_context 'sftp'

  let(:file_path) { '/any/old/path' }

  before do
    allow(sftp_session).to receive(:download!)
  end

  it 'registers a Shared::Sftp' do
    expect(oclc_sftp).to be_an_instance_of(Shared::Sftp)
  end

  it 'has OCLC sftp configuration' do
    expect(oclc_sftp.sftp_host).to eq('localhost2')
    expect(oclc_sftp.sftp_username).to eq('fx_pul')
  end

  it 'downloads over sftp' do
    oclc_sftp.start { |sftp| sftp.download!(file_path) }
    expect(sftp_session).to have_received(:download!).with(file_path).once
  end
end
