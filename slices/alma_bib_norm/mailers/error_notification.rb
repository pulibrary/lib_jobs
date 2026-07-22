# frozen_string_literal: true
require 'hanami/mailer'

module AlmaBibNorm
  module Mailers
    class ErrorNotification < Hanami::Mailer
      from 'lib-jobs@princeton.edu'
      to Slice.settings.alma_bib_norm_error_recipients.split(',')
      subject 'PulBibNorm POST error'

      expose :error_code
      expose :error_message
    end
  end
end
