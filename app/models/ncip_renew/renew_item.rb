# frozen_string_literal: true
module NCIPRenew
  class RenewItem
    attr_reader :doc

    def initialize(doc)
      @doc = doc
    end

    def response
      Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml['ns1'].NCIPMessage('xmlns:ns1' => 'http://www.niso.org/2008/ncip',
                               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                               'ns1:version' => 'http://www.niso.org/schemas/ncip/v2_0/imp1/xsd/ncip_v2_0.xsd') do
          xml['ns1'].RenewItemResponse do
            header(xml)
            body(xml)
          end
        end
      end.to_xml
    end

    private

    def header(xml)
      xml['ns1'].InitiationHeader do
        xml['ns1'].FromAgencyId do
          xml['ns1'].AgencyId from_agency
        end
        xml['ns1'].ToAgencyId do
          xml['ns1'].AgencyId from_agency
        end
        xml['ns1'].ApplicationProfileType application_profile
      end
    end

    def body(xml)
      xml['ns1'].UserId do
        xml['ns1'].UserIdentifierValue user_id
      end
      xml['ns1'].ItemId do
        xml['ns1'].ItemIdentifierValue item_id
      end
      xml['ns1'].DateDue due_date
    end

    def renew_item
      @renew_item ||= doc.at_xpath("ns1:NCIPMessage//ns1:RenewItem")
    end

    def from_agency
      @from_agency ||= renew_item.at_xpath("ns1:InitiationHeader//ns1:FromAgencyId//ns1:AgencyId").text
    end

    def to_agency
      @to_agency ||= renew_item.at_xpath("ns1:InitiationHeader//ns1:ToAgencyId//ns1:AgencyId").text
    end

    def application_profile
      @application_profile ||= renew_item.at_xpath("ns1:InitiationHeader//ns1:ApplicationProfileType").text
    end

    def user_id
      @user_id ||= renew_item.at_xpath("ns1:UserId//ns1:UserIdentifierValue").text
    end

    def item_id
      @item_id ||= renew_item.at_xpath("ns1:ItemId//ns1:ItemIdentifierValue").text
    end

    def due_date
      @due_date ||= renew_item.at_xpath("ns1:DesiredDateDue").text
    end
  end
end
