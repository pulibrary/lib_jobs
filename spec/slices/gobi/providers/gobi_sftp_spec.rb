# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'gobi_sftp provider', type: :model do
  subject(:gobi_sftp) { Gobi::Slice['gobi_sftp'] }

  include_context 'sftp'

  let(:file_path) { '/any/old/path' }

  before do
    allow(sftp_session).to receive(:download!)
  end

  it 'registers a Shared::Sftp' do
    expect(gobi_sftp).to be_an_instance_of(Shared::Sftp)
  end

  it 'has Gobi sftp configuration' do
    expect(gobi_sftp.sftp_host).to eq('localhost2')
    expect(gobi_sftp.sftp_username).to eq('gobi')
  end

  it 'allows less secure algorithms' do
    gobi_sftp.start { |sftp| sftp.download!(file_path) }
    expect(Net::SFTP).to have_received(:start).with('localhost2', 'gobi', { password: 'change_me', append_all_supported_algorithms: true }).once
  end
end
