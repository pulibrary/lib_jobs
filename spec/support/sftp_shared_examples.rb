# frozen_string_literal: true

RSpec.shared_examples 'an sftp' do
  include_context 'sftp'
  let(:sftp) { described_class.new }
  let(:file_path) { '/any/old/path' }

  before do
    allow(sftp_session).to receive(:download!)
  end

  it 'can be instantiated without arguments' do
    expect { described_class.new }.not_to raise_error
  end

  it 'can be instantiated with arguments' do
    expect(described_class.new(sftp_host: 'some_host', sftp_username: 'some_username', sftp_password: 'some_password')).to be
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
