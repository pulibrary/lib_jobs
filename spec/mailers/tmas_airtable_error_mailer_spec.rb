# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TMASAirtableErrorMailer, type: :mailer do
  it 'send an email about the failure' do
    mail = described_class.error_notification(
        Failure('Could not get data from TMAS!'),
        { 'TMAS_AIRTABLE_ERROR_EMAILS' => 'a@example.com,b@example.com' }
      )
    expect(mail.subject).to eq('Error syncing TMAS data with Airtable')
    expect(mail.to).to eq(['a@example.com', 'b@example.com'])
    expect(mail.from).to eq(["lib-jobs@princeton.edu"])
    expect(mail.text_part.body.encoded).to include 'Could not get data from TMAS!'
    expect(mail.html_part.body.encoded).to include 'Could not get data from TMAS!'
  end
end
