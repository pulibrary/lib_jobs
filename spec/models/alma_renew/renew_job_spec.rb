# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaRenew::RenewJob, type: :model do
  let(:today) { Time.zone.now.strftime("%m%d%Y") }
  let(:sftp_entry1) { instance_double("Net::SFTP::Protocol::V01::Name", name: "abc.csv") }
  let(:sftp_session) { instance_double("Net::SFTP::Session", dir: sftp_dir) }
  let(:sftp_dir) { instance_double("Net::SFTP::Operations::Dir") }

  let(:valid_response) do
    "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" \
    "<ns1:NCIPMessage xmlns:ns1=\"http://www.niso.org/2008/ncip\" ns1:version=\"http://www.niso.org/schemas/ncip/v2_0/imp1/xsd/ncip_v2_0.xsd\">" \
    "<ns1:RenewItemResponse><ns1:ResponseHeader><ns1:FromAgencyId><ns1:AgencyId>01PRI_INST</ns1:AgencyId></ns1:FromAgencyId>" \
    "<ns1:ToAgencyId><ns1:AgencyId>01PRI_INST</ns1:AgencyId></ns1:ToAgencyId></ns1:ResponseHeader>" \
    "<ns1:ItemId><ns1:ItemIdentifierValue>32044061963013</ns1:ItemIdentifierValue></ns1:ItemId>" \
    "<ns1:UserId><ns1:UserIdentifierValue>999999999</ns1:UserIdentifierValue></ns1:UserId>" \
    "<ns1:DateDue>2022-06-20T00:00:00.000Z</ns1:DateDue></ns1:RenewItemResponse></ns1:NCIPMessage>"
  end
  let(:invalid_response) do
    "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" \
    "<ns1:NCIPMessage xmlns:ns1=\"http://www.niso.org/2008/ncip\" ns1:version=\"http://www.niso.org/schemas/ncip/v2_0/imp1/xsd/ncip_v2_0.xsd\">" \
    "<ns1:RenewItemResponse><ns1:ResponseHeader><ns1:FromAgencyId><ns1:AgencyId>01PRI_INST</ns1:AgencyId></ns1:FromAgencyId>"\
    "<ns1:ToAgencyId><ns1:AgencyId>01PRI_INST</ns1:AgencyId></ns1:ToAgencyId></ns1:ResponseHeader><ns1:Problem>" \
    "<ns1:ProblemType>Unknown Item</ns1:ProblemType><ns1:ProblemDetail>Unknown Item</ns1:ProblemDetail><ns1:ProblemElement>//RenewItem/ItemId</ns1:ProblemElement>" \
    "<ns1:ProblemValue>23915763110006421</ns1:ProblemValue></ns1:Problem></ns1:RenewItemResponse></ns1:NCIPMessage>"
  end

  let(:due_date_56day) { 56.days.from_now.strftime('%Y-%m-%d') }

  describe "#run" do
    before do
      stub_request(:post, "https://princeton.alma.exlibrisgroup.com/view/NCIPServlet")
        .with { |request| request.body.include? "32044061963013" }
        .to_return(status: 200, body: valid_response, headers: {})

      stub_request(:post, "https://princeton.alma.exlibrisgroup.com/view/NCIPServlet")
        .with { |request| request.body.include? "33433084897390" }
        .to_return(status: 200, body: valid_response, headers: {})

      stub_request(:post, "https://princeton.alma.exlibrisgroup.com/view/NCIPServlet")
        .with { |request| request.body.include? "CU53967402" }
        .to_return(status: 200, body: invalid_response, headers: {})

      stub_request(:post, "https://princeton.alma.exlibrisgroup.com/view/NCIPServlet")
        .with { |request| request.body.include? "CU63769409" }
        .to_return(status: 200, body: valid_response, headers: {})

      stub_request(:post, "https://princeton.alma.exlibrisgroup.com/view/NCIPServlet")
        .with { |request| request.body.include? "CU63769408" }
        .to_return(status: 200, body: valid_response, headers: {})
    end
    it "generates an xml file" do
      allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry1)
      allow(sftp_session).to receive(:download!).with("/alma/scsb_renewals/abc.csv").and_return(Rails.root.join('spec', 'fixtures', 'renew.csv').read)
      allow(sftp_session).to receive(:rename).with("/alma/scsb_renewals/abc.csv", "/alma/scsb_renewals/abc.csv.processed")
      allow(Net::SFTP).to receive(:start).and_yield(sftp_session)

      renew_job = described_class.new
      expect(renew_job.run).to be_truthy
      expect(sftp_session).to have_received(:download!).with("/alma/scsb_renewals/abc.csv")
      expect(sftp_session).to have_received(:rename).with("/alma/scsb_renewals/abc.csv", "/alma/scsb_renewals/abc.csv.processed")
      data_set = DataSet.last
      expect(data_set.category).to eq("AlmaRenew")
      expect(data_set.data).to eq("We tried to send renewals for 5 items. 1 errors were encountered.\n Unknown Item (23915763110006421)")
      expect(data_set.report_time.to_date).to eq(Time.zone.now.to_date)
    end
  end
end