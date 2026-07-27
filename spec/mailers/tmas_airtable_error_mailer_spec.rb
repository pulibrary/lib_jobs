# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TMASGateCounts::Mailers::ErrorNotification, type: :mailer do
  it 'send an email about the failure' do
    mail = described_class.new.deliver(
        failure: Failure('Could not get data from TMAS!')
      ).message
    expect(mail.subject).to eq('Error syncing TMAS data with Airtable')
    expect(mail.to).to eq(['a@example.com', 'b@example.com'])
    expect(mail.from).to eq(["lib-jobs@princeton.edu"])
    expect(mail.text_body).to include 'Could not get data from TMAS!'
    expect(mail.html_body).to include 'Could not get data from TMAS!'
  end
end
