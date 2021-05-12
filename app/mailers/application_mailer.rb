# frozen_string_literal: true
class ApplicationMailer < ActionMailer::Base
  default from: "lib-jobs@princeton.edu"
  layout 'mailer'
end
