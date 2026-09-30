# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Aspace2almaHelper do
  let(:sftp_session) { instance_double(Net::SFTP::Session) }
  let(:file_exists) { true }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('SFTP_HOST', nil).and_return('sftp.example.edu')
    allow(ENV).to receive(:fetch).with('SFTP_USERNAME', nil).and_return('alma_user')
    allow(ENV).to receive(:fetch).with('SFTP_PASSWORD', nil).and_return('secret')
    allow(Net::SFTP).to receive(:start).and_yield(sftp_session)
    allow(sftp_session).to receive(:stat).and_yield(instance_double(Net::SFTP::Response, ok?: file_exists))
    allow(sftp_session).to receive(:remove!)
    allow(sftp_session).to receive(:rename!)
  end

  describe '.remove_file' do
    it 'connects with the SFTP settings' do
      described_class.remove_file('/alma/aspace/MARC_out_old.xml')

      expect(Net::SFTP).to have_received(:start).with('sftp.example.edu', 'alma_user', { password: 'secret' })
    end

    it 'removes the file when it exists' do
      described_class.remove_file('/alma/aspace/MARC_out_old.xml')

      expect(sftp_session).to have_received(:remove!).with('/alma/aspace/MARC_out_old.xml')
    end

    context 'when the file does not exist' do
      let(:file_exists) { false }

      it 'does nothing' do
        described_class.remove_file('/alma/aspace/MARC_out_old.xml')

        expect(sftp_session).not_to have_received(:remove!)
      end
    end
  end

  describe '.rename_file' do
    it 'renames the file when it exists' do
      described_class.rename_file('/alma/aspace/MARC_out.xml', '/alma/aspace/MARC_out_old.xml')

      expect(sftp_session).to have_received(:rename!).with('/alma/aspace/MARC_out.xml', '/alma/aspace/MARC_out_old.xml')
    end

    context 'when the file does not exist' do
      let(:file_exists) { false }

      it 'does nothing' do
        described_class.rename_file('/alma/aspace/MARC_out.xml', '/alma/aspace/MARC_out_old.xml')

        expect(sftp_session).not_to have_received(:rename!)
      end
    end
  end

  describe '.rotate_file' do
    before do
      allow(described_class).to receive(:remove_file)
      allow(described_class).to receive(:rename_file)
    end

    it 'removes the previous _old file, then renames the current file to _old' do
      described_class.rotate_file('MARC_out.xml')

      expect(described_class).to have_received(:remove_file).with('/alma/aspace/MARC_out_old.xml').ordered
      expect(described_class).to have_received(:rename_file)
        .with('/alma/aspace/MARC_out.xml', '/alma/aspace/MARC_out_old.xml').ordered
    end

    it 'renames marcao_export.xml to marcao_export_old.xml' do
      described_class.rotate_file('marcao_export.xml')

      expect(described_class).to have_received(:rename_file)
        .with('/alma/aspace/marcao_export.xml', '/alma/aspace/marcao_export_old.xml')
    end
  end
end
