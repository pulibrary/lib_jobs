# frozen_string_literal: true
class NewlyCatalogedMailer < ApplicationMailer
  def report(selector:, file_path:)
    week_string = Time.now.utc.strftime('%B %e, %Y')
    @subject = "LC Slips for the week of #{week_string}"
    file_name = Pathname.new(file_path).basename.to_s
    attachments[file_name] = File.read(file_path)
    mail(subject: @subject,
         cc: 'pdiskin@princeton.edu',
         to: selector.email)
  end
end
