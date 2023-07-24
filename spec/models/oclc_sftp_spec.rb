# frozen_string_literal: true
require "rails_helper"

RSpec.describe OclcSftp, type: :model do
  let(:subject) { described_class.new }

  it 'has configuration' do
    allow(Rails.application.config).to receive(:oclc_sftp).and_call_original
    expect(Rails.application.config.oclc_sftp.host).to eq('localhost2')
  end

  it 'can be initialized without arguments' do
    expect(described_class.new).to be
  end

  it 'can be initialized with arguments' do
    expect(described_class.new(sftp_host: 'some_host', sftp_username: 'some_username', sftp_password: 'some_password')).to be
  end

  it 'can access stfp info' do
    expect(subject.sftp_host).to eq('localhost2')
    expect(subject.sftp_username).to eq('fx_pul')
  end

  context 'with a mocked sftp connection' do
    let(:sftp_session) { instance_double("Net::SFTP::Session", dir: sftp_dir) }
    let(:sftp_dir) { instance_double("Net::SFTP::Operations::Dir") }
    let(:file_path) { "spec/fixtures/oclc/metacoll.PUL.new.D20230706.T213019.MZallDLC.1.mrc" }
    before do
      allow(sftp_session).to receive(:download!).with(file_path).and_return(Rails.root.join('spec', 'fixtures', 'oclc', 'metacoll.PUL.new.D20230706.T213019.MZallDLC.1.mrc').read)
      allow(Net::SFTP).to receive(:start).and_yield(sftp_session)
    end
    it 'downloads over sftp' do
      subject.start { |sftp| sftp.download!(file_path) }
      expect(sftp_session).to have_received(:download!).with(file_path).once
    end
  end
end
