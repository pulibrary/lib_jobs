# frozen_string_literal: true
require "rails_helper"

RSpec.describe Sftp, type: :model do
  include_context 'sftp'

  let(:subject) { described_class.new(sftp_host: "example.com", sftp_username: "name", sftp_password: "pass") }
  let(:file_path) { "/alma/invoices/abc.xml" }

  before do
    allow(sftp_session).to receive(:download!).with(file_path).and_return(Rails.root.join('spec', 'fixtures', 'invoice_export_202118300518.xml').read)
  end
  it 'raises an error when instantiated without arguments' do
    expect { described_class.new }.to raise_error(ArgumentError)
  end
  it 'downloads over sftp' do
    subject.start { |sftp| sftp.download!(file_path) }
    expect(sftp_session).to have_received(:download!).with(file_path).once
  end

  describe 'allowing all supported algorithms' do
    it 'defaults to not appending all supported algorithms' do
      subject.start { |sftp| sftp.download!(file_path) }
      expect(Net::SFTP).to have_received(:start).with("example.com", "name", { password: "pass", append_all_supported_algorithms: false }).once
    end

    context 'when you want to allow less secure algorithms' do
      let(:subject) { described_class.new(sftp_host: "example.com", sftp_username: "name", sftp_password: "pass", allow_less_secure_algorithms: true) }

      it 'can append all supported algorithms' do
        subject.start { |sftp| sftp.download!(file_path) }
        expect(Net::SFTP).to have_received(:start).with("example.com", "name", { password: "pass", append_all_supported_algorithms: true }).once
      end
    end
  end

  context 'with a spotty sftp connection' do
    before do
      allow(sftp_session).to receive(:download!).with(file_path).and_return(Rails.root.join('spec', 'fixtures', 'invoice_export_202118300518.xml').read)
      allow(Net::SFTP).to receive(:start).and_raise(Net::SSH::Disconnect)
      allow(Rails.logger).to receive(:warn)
      allow(Rails.logger).to receive(:error)
    end
    it 'tries the download 4 times, then stops' do
      subject.start { |sftp| sftp.download!(file_path) }
      expect(Net::SFTP).to have_received(:start).exactly(4).times
      expect(Rails.logger).to have_received(:warn).exactly(3).times
      expect(Rails.logger).to have_received(:error).once
    end
  end
end
