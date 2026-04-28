# frozen_string_literal: true
class TMASAirtableErrorMailer < ApplicationMailer
  def error_notification(failure, env = ENV)
    @failure = failure
    mail(to: env['TMAS_AIRTABLE_ERROR_EMAILS'], subject: 'Error syncing TMAS data with Airtable')
  end
end
