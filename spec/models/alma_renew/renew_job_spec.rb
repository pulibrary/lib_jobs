# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaRenew::RenewJob, type: :model do
  include_context 'sftp'

  let(:today) { Time.zone.now.strftime("%m%d%Y") }
  let(:sftp_entry1) { instance_double("Net::SFTP::Protocol::V01::Name", name: "abc.csv") }

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

  let(:renew_csv) { Rails.root.join('spec', 'fixtures', 'renew.csv').read }
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
      allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry1)
      allow(sftp_session).to receive(:download!).with("/alma/scsb_renewals/abc.csv").and_return(renew_csv)
      allow(sftp_session).to receive(:rename).with("/alma/scsb_renewals/abc.csv", "/alma/scsb_renewals/abc.csv.processed")
    end
    let(:expected_data_message) do
      "We received 5 renewal requests. We tried to send renewals for 5 items. 1 errors were encountered.\n Unknown Item (23915763110006421)"
    end
    it "generates an xml file" do
      renew_job = described_class.new
      allow(renew_job).to receive(:ncip_request).and_call_original
      expect(renew_job.run).to be_truthy
      expect(renew_job).to have_received(:ncip_request).exactly(5).times
      expect(sftp_session).to have_received(:download!).with("/alma/scsb_renewals/abc.csv")
      expect(sftp_session).to have_received(:rename).with("/alma/scsb_renewals/abc.csv", "/alma/scsb_renewals/abc.csv.processed")
      data_set = DataSet.last
      expect(data_set.category).to eq("AlmaRenew")
      expect(data_set.data).to eq(expected_data_message)
      expect(data_set.report_time.to_date).to eq(Time.zone.now.to_date)
    end

    context 'with an item without a primary identifier / user_id' do
      let(:renew_csv) { Rails.root.join('spec', 'fixtures', 'renew_no_user_id.csv').read }
      let(:expected_data_message) do
        "We received 5 renewal requests. We tried to send renewals for 4 items. 2 errors were encountered.\n" \
        " User cannot be 'None' (Barcode: 32044061963013)\nUnknown Item (23915763110006421)"
      end

      it "generates an xml file" do
        renew_job = described_class.new
        allow(renew_job).to receive(:ncip_request).and_call_original
        expect(renew_job.run).to be_truthy
        expect(renew_job).to have_received(:ncip_request).exactly(4).times
        data_set = DataSet.last
        expect(data_set.data).to eq(expected_data_message)
      end
    end

    context 'with items without user ids or expiration dates' do
      let(:renew_csv) { Rails.root.join('spec', 'fixtures', 'renew_no_id_no_expiration.csv').read }
      let(:expected_data_message) do
        "We received 6 renewal requests. We tried to send renewals for 3 items. 3 errors were encountered.\n" \
        " User cannot be 'None' (Barcode: 32044061963013)\nExpiration date cannot be blank (Barcode: CU53967402)\n" \
        "Expiration date cannot be blank, User cannot be 'None' (Barcode: CU63769408)"
      end
      it 'generates an xml file that doesn not include the invalid item' do
        renew_job = described_class.new
        allow(renew_job).to receive(:ncip_request).and_call_original
        expect(renew_job.run).to be_truthy
        expect(renew_job).to have_received(:ncip_request).exactly(3).times

        data_set = DataSet.last
        expect(data_set.data).to eq(expected_data_message)
      end
    end

    context 'when there is a Net::ReadTimeout in ncip_renew_item with one item' do
      before do
        stub_request(:post, "https://princeton.alma.exlibrisgroup.com/view/NCIPServlet")
          .with { |request| request.body.include? "32044061963013" }
          .to_raise(Net::ReadTimeout)
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:error)
      end

      it 'retries the one item 3 times' do
        renew_job = described_class.new
        allow(renew_job).to receive(:ncip_request).and_call_original
        expect(renew_job.run).to be_truthy
        expect(renew_job).to have_received(:ncip_request).exactly(5).times
        expect(a_request(:post, "https://princeton.alma.exlibrisgroup.com/view/NCIPServlet")
        .with { |request| request.body.include? "32044061963013" }).to have_been_made.times(3)
        expect(Rails.logger).to have_received(:warn).exactly(2).times
        expect(Rails.logger).to have_received(:error).once
        data_set = DataSet.last
        expect(data_set.data).to include('Encountered Net::ReadTimeout: Renewal unsuccessful for item with barcode: 32044061963013')
      end
    end
  end
end
