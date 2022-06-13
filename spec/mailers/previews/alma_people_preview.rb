# frozen_string_literal: true
# Preview all emails at http://localhost:3000/rails/mailers/alma_people
class AlmaPeoplePreview < ActionMailer::Preview
  def error_notification
    xml = AlmaPeople::AlmaXmlPerson.new(xml: Nokogiri::XML::Builder.new, person: { 'CAMPUS_ID' => 'netid', 'EMPLID' => '9999999' })
    xml.valid?
    AlmaPeopleMailer.error_notification(invalid_records: [xml])
  end
end
