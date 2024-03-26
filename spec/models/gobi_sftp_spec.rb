# frozen_string_literal: true
require "rails_helper"

RSpec.describe GobiSftp, type: :model do
  it_behaves_like 'an sftp'
  include_context 'sftp'
  let(:file_path) { '/any/old/path' }

  before do
    allow(sftp_session).to receive(:download!)
  end

  it 'defaults to allowing less secure algorithms' do
    described_class.new.start { |sftp| sftp.download!(file_path) }
    expect(Net::SFTP).to have_received(:start).with("localhost2", "gobi", { password: "pass", append_all_supported_algorithms: true }).once
  end
end
