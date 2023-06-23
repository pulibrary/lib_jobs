# frozen_string_literal: true
require "rails_helper"

RSpec.describe AlmaSftp, type: :model do
  let(:subject) { described_class.new }
  let(:sftp_session) { instance_double("Net::SFTP::Session", dir: sftp_dir) }
  let(:sftp_dir) { instance_double("Net::SFTP::Operations::Dir") }
  let(:file_path) { "/alma/invoices/abc.xml" }

  before do
    allow(sftp_session).to receive(:download!).with(file_path).and_return(Rails.root.join('spec', 'fixtures', 'invoice_export_202118300518.xml').read)
    allow(Net::SFTP).to receive(:start).and_yield(sftp_session)
  end
  it 'downloads over sftp' do
    subject.start { |sftp| sftp.download!(file_path) }
    expect(sftp_session).to have_received(:download!).with(file_path).once
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
