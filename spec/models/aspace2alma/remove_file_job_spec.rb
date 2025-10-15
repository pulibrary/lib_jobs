# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Aspace2alma::RemoveFileJob do
  it 'removes the existing file from the sftp server' do
    sftp_session = instance_double(Net::SFTP::Session)
    allow(sftp_session).to receive(:stat).and_yield(instance_double(Net::SFTP::Response, ok?: true))
    allow(sftp_session).to receive(:remove!)
    allow(Net::SFTP).to receive(:start).and_yield(sftp_session)

    described_class.new.run

    expect(sftp_session).to have_received(:remove!).with('/alma/aspace/MARC_out.xml')
  end
end
