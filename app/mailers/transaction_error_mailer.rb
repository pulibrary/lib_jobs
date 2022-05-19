# frozen_string_literal: true
class TransactionErrorMailer < ApplicationMailer
  def report(duplicate_ids:)
    @duplicate_ids = duplicate_ids
    mail(to: LibJobs.config[:transaction_error_feed_recipients], subject: 'PeopleSoft Duplicate Transactions')
  end
end
