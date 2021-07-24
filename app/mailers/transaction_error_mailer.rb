# frozen_string_literal: true
class TransactionErrorMailer < ApplicationMailer
  def report(duplicate_ids:)
    @duplicate_ids = duplicate_ids
    mail(to: "cac9@princeton.edu, mzelesky@princeton.edu, kr2@princeton.edu", subject: 'PeopleSoft Duplicate Transactions')
  end
end
