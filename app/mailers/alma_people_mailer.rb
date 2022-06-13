# frozen_string_literal: true
class AlmaPeopleMailer < ApplicationMailer
  def error_notification(invalid_records:)
    @invalid_records = invalid_records
    mail(to: LibJobs.config[:alma_people_error_notification_recipients], subject: 'Peoplesoft to Alma Person loading error(s)')
  end
end
