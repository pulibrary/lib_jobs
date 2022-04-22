# frozen_string_literal: true
module AlmaRenew
  class Item
    attr_reader :from_agency_id, :to_agency_id, :application_profile, :expiration_date, :user_id, :item_barcode, :user_group

    def initialize(item_hash, from_agency_id: LibJobs.config[:ncip_renew_from_agency], to_agency_id: LibJobs.config[:ncip_renew_to_agency],
                   application_profile: LibJobs.config[:ncip_renew_application_profile])
      @from_agency_id = from_agency_id
      @to_agency_id = to_agency_id
      @application_profile = application_profile
      @expiration_date = item_hash["Expiry Date"]
      @user_id = item_hash["Primary Identifier"]
      @item_barcode = item_hash["Barcode"]
      @user_group = item_hash["Patron Group"]
    end

    def ncip
      ncip_renew_body(due_date: calculate_due_date).to_xml
    end

    private

    def calculate_due_date
      new_date = case user_group
                 when "SENR Senior Undergraduate"
                   calculate_by_date(this_year_cutoff_mon: 5, this_year_cutoff_day: 10, due_date_mon: 5, due_date_day: 10)
                 when "GRAD Graduate Student", "P Faculty & Professional"
                   calculate_by_date(this_year_cutoff_mon: 4, this_year_cutoff_day: 30, due_date_mon: 6, due_date_day: 15)
                 else
                   DateTime.now + 56.days
                 end
      if new_date > expiration_date
        expiration_date
      else
        new_date
      end.to_date
    end

    def calculate_by_date(this_year_cutoff_mon:, this_year_cutoff_day:, due_date_mon:, due_date_day:)
      today = DateTime.now
      cutoff = DateTime.new(today.year, this_year_cutoff_mon, this_year_cutoff_day)
      due_date_year = if today >= cutoff
                        today.year + 1
                      else
                        today.year
                      end
      DateTime.new(due_date_year, due_date_mon, due_date_day)
    end

    # disabling these metrics, since it makes sense to just build the XML in one routine
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def ncip_renew_body(due_date:)
      Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml['ns1'].NCIPMessage('xmlns:ns1' => 'http://www.niso.org/2008/ncip',
                               'ns1:version' => 'http://www.niso.org/schemas/ncip/v2_0/imp1/xsd/ncip_v2_0.xsd',
                               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance') do
          xml['ns1'].RenewItem do
            xml['ns1'].InitiationHeader do
              xml['ns1'].FromAgencyId do
                xml['ns1'].AgencyId from_agency_id
              end
              xml['ns1'].ToAgencyId do
                xml['ns1'].AgencyId to_agency_id
              end
              xml['ns1'].ApplicationProfileType application_profile
            end
            xml['ns1'].UserId do
              xml['ns1'].UserIdentifierValue user_id
            end
            xml['ns1'].ItemId do
              xml['ns1'].ItemIdentifierValue item_barcode
            end
            xml['ns1'].DesiredDateDue due_date
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
end
