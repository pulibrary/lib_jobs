# frozen_string_literal: true
class AlmaBibNormMailer < ApplicationMailer
  def error_notification(error_code, error_message)
    @error_code = error_code
    @error_message = error_message
    mail(to: LibJobs.config[:alma_bib_norm_error_recipients], subject: 'PulBibNorm POST error')
  end
end
