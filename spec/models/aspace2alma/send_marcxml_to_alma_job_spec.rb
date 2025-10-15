# frozen_string_literal: false

require 'rails_helper'
require 'stringio'

def stub_aspace_login
  allow(ENV).to receive(:fetch).and_call_original
  allow(ENV).to receive(:fetch).with("ASPACE_URL", nil).and_return("https://example.com/staff/api")
  allow(ENV).to receive(:fetch).with("ASPACE_USER", nil).and_return("test_user")
  allow(ENV).to receive(:fetch).with("ASPACE_PASSWORD", nil).and_return("test_pw")
  stub_request(:post, "https://example.com/staff/api/users/test_user/login?password=test_pw")
    .to_return(
      status: 200,
      body: { "session" => "some_long_hash" }.to_json
    )
end

RSpec.describe Aspace2alma::SendMarcxmlToAlmaJob do
  let(:resource_uris) do
    ["/repositories/3/resources/1511", "/repositories/3/resources/1512"]
  end
  let(:sftp_session) { instance_double("Net::SFTP::Session", dir: sftp_dir) }
  let(:sftp_dir) { instance_double("Net::SFTP::Operations::Dir") }
  let(:response) { instance_double("ArchivesSpace::Response") }
  let(:client) { ArchivesSpace::Client.new(ArchivesSpace::Configuration.new(base_uri: 'https://example.com/staff/api')) }
  let(:frozen_time) { Time.utc(2023, 10, 8, 12, 3, 1) }

  around do |example|
    FileUtils.rm_f('MARC_out.xml')
    example.run
    FileUtils.rm_f('MARC_out.xml')
  end
  after do
    Timecop.return
  end
  before do
    Timecop.freeze(frozen_time)
    stub_aspace_login
    allow(Net::SFTP).to receive(:start).and_yield(sftp_session)
    allow(Aspace2alma::AlmaDuplicateBarcodeCheck).to receive(:new).and_return(instance_double(Aspace2alma::AlmaDuplicateBarcodeCheck, duplicate?: true))
    allow(sftp_session).to receive(:stat)
      .with("/alma/aspace/MARC_out.xml")
      .and_yield(instance_double(Net::SFTP::Response, ok?: true))
    allow(sftp_session).to receive(:stat)
      .with("/alma/aspace/MARC_out_old.xml")
      .and_yield(instance_double(Net::SFTP::Response, ok?: true))
    allow(sftp_session).to receive(:remove!)
      .with("/alma/aspace/MARC_out_old.xml")
    allow(sftp_session).to receive(:rename!)
      .with("/alma/aspace/MARC_out.xml", "/alma/aspace/MARC_out_old.xml")
    allow(ArchivesSpace::Client).to receive(:new).and_return(client)
    allow(client).to receive(:login).and_return(client)
    allow(client).to receive(:get).and_call_original
    allow(client).to receive(:get).with("repositories/3/top_containers/search",
      query: { q: "collection_uri_u_sstr:\"/repositories/3/resources/1511\"" }).and_return(response)
    allow(client).to receive(:get).with("repositories/3/top_containers/search",
        query: { q: "collection_uri_u_sstr:\"/repositories/3/resources/1512\"" }).and_return(response)
    allow(response).to receive(:parsed).and_return(JSON.parse(File.read(file_fixture("aspace2alma/container_response.json"))))
    allow_any_instance_of(described_class).to receive(:get_resource_uris_for_all_repos) { resource_uris }
    allow(Aspace2almaHelper).to receive(:alma_sftp) { 'MARC_out.xml' }
  end

  context 'when the connection is stable' do
    before do
      stub_request(:get, "https://example.com/staff/api/repositories/3/resources/marc21/1511.xml")
        .and_return(status: 200, body: File.read(file_fixture('aspace2alma/marc_1511.xml')))
      stub_request(:get, "https://example.com/staff/api/repositories/3/top_containers/search?q=collection_uri_u_sstr:%22/repositories/3/resources/1511%22")
        .and_return(status: 200, body: "")
      stub_request(:get, "https://example.com/staff/api/repositories/3/resources/marc21/1512.xml")
        .and_return(status: 200, body: File.read(file_fixture('aspace2alma/marc_1512.xml')))
      described_class.new.run
    end

    let(:doc) { Nokogiri::XML(File.open('MARC_out.xml')) }

    context 'when aspace returns multiple records' do
      it 'adds a (PULFA) 035 field' do
        expect(doc.xpath('//marc:datafield[@tag = "035"]/marc:subfield/text()').map(&:to_s))
          .to match_array(["(PULFA)MC001.01", "(PULFA)MC001.02.01"])
      end
    end

    context 'when aspace returns a single record' do
      let(:resource_uris) { ["/repositories/3/resources/1511"] }
      let(:doc_file) { File.open('MARC_out.xml') }
      let(:doc_after_processing_fixture) { File.open(file_fixture('aspace2alma/doc_after_processing.xml')) }

      it 'corrects the data in the 040 field' do
        subfield_b_xpath = '//marc:datafield[@tag = "040"]/marc:subfield[@code = "b"]/text()'
        subfield_e_xpath = '//marc:datafield[@tag = "040"]/marc:subfield[@code = "e"]/text()'
        expect(doc.at(subfield_b_xpath).to_s).to eq('eng')
        expect(doc.at(subfield_e_xpath).to_s).to eq('dacs')
      end
      it 'creates the expected document' do
        expect(File.read(doc_file)).to eq(File.read(doc_after_processing_fixture))
      end
    end
  end

  context 'when aspace is down' do
    before do
      allow_any_instance_of(described_class).to receive(:aspace_login).and_raise(RuntimeError)
    end
    it 'deletes the MARCxml file from lib-sftp' do
      expect { described_class.new.run }.to raise_error
      expect(sftp_session).to have_received(:remove!)
        .with("/alma/aspace/MARC_out_old.xml")
      expect(sftp_session).to have_received(:rename!)
        .with("/alma/aspace/MARC_out.xml", "/alma/aspace/MARC_out_old.xml")
    end
  end

  describe 'ItemRecordConstructor' do
    let(:resource_uri) { "/repositories/3/resources/1511" }

    it 'can be instantiated' do
      expect { Aspace2alma::ItemRecordConstructor.new(client, instance_double(Aspace2alma::AlmaDuplicateBarcodeCheck)) }.not_to raise_error
    end

    it 'creates ItemParams struct correctly' do
      log_out = StringIO.new
      doc = Nokogiri::XML('<test/>')
      tag099_a = doc.at_xpath('//test')

      expect { Aspace2alma::ItemParams.new(doc, tag099_a, log_out, nil) }.not_to raise_error
    end
  end

  context 'when the connection is interrupted during a record retrieval' do
    before do
      stub_request(:get, "https://example.com/staff/api/repositories/3/resources/marc21/1511.xml")
        .to_raise(Errno::ECONNRESET)
      stub_request(:get, "https://example.com/staff/api/repositories/3/resources/marc21/1512.xml")
        .and_return(status: 200, body: File.read(file_fixture('aspace2alma/marc_1512.xml')))
    end
    it 'retries the record' do
      described_class.new.run
      # Since we are rescuing from this error, it is not actually raised
      # but this was the intermediate step to make sure our test setup was raising the error correctly
      # expect { described_class.new.run }.to raise_error(Errno::ECONNRESET)
      expect(a_request(:get, "https://example.com/staff/api/repositories/3/resources/marc21/1511.xml"))
        .to have_been_made.times(4)
      expect(a_request(:get, "https://example.com/staff/api/repositories/3/resources/marc21/1512.xml"))
        .to have_been_made.times(1)
    end
  end
end
