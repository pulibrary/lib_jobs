# frozen_string_literal: true

RSpec.shared_context 'sftp' do
  let(:sftp_session) { instance_double("Net::SFTP::Session", dir: sftp_dir) }
  let(:sftp_dir) { instance_double("Net::SFTP::Operations::Dir") }

  before do
    allow(Net::SFTP).to receive(:start).and_yield(sftp_session)
  end
end
