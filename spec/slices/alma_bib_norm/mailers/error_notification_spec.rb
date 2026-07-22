# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaBibNorm::Mailers::ErrorNotification do
  let(:mail) { described_class.new.deliver(error_code: '400', error_message: 'Invalid format for job_id. Value: 123456. Valid format: Job type prefix (S,M,O) followed by digits') }

  it 'renders the headers' do
    expect(mail.message.subject).to eq('PulBibNorm POST error')
    expect(mail.message.to).to eq(['person_4@princeton.edu', 'person_5@princeton.edu'])
    expect(mail.message.from).to eq(['lib-jobs@princeton.edu'])
  end

  it 'includes error code in mail text' do
    expect(mail.message.html_body).to include('400')
    expect(mail.message.text_body).to include('400')
  end

  it 'includes error message in mail text' do
    expect(mail.message.html_body).to include('Invalid format for job_id. Value: 123456')
    expect(mail.message.text_body).to include('Invalid format for job_id. Value: 123456')
  end
end
