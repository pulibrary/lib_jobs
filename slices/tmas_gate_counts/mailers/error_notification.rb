# frozen_string_literal: true
require 'hanami/mailer'

module TMASGateCounts
  module Mailers
    class ErrorNotification < Hanami::Mailer
      from 'lib-jobs@princeton.edu'
      to Slice.settings.tmas_airtable_error_emails.split(',')
      subject 'Error syncing TMAS data with Airtable'
      expose :failure
    end
  end
end
