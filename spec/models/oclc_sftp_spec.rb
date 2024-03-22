# frozen_string_literal: true
require "rails_helper"

RSpec.describe OclcSftp, type: :model do
  it_behaves_like 'an sftp'
  let(:subject) { described_class.new }

  it 'has configuration' do
    allow(Rails.application.config).to receive(:oclc_sftp).and_call_original
    expect(Rails.application.config.oclc_sftp.host).to eq('localhost2')
  end

  it 'can access stfp info' do
    expect(subject.sftp_host).to eq('localhost2')
    expect(subject.sftp_username).to eq('fx_pul')
  end
end
