# frozen_string_literal: true
require 'rails_helper'

RSpec.shared_context 'with common mocks' do
  let(:mock_client) { instance_spy(ArchivesSpace::Client) }
  let(:constructor) do
    validator = instance_double(Aspace2alma::AlmaDuplicateBarcodeCheck, duplicate?: false)
    Aspace2alma::ItemRecordConstructor.new(mock_client, validator)
  end
  let(:resource_uri) { '/repositories/2/resources/123' }
  let(:mock_doc) { instance_spy(Nokogiri::XML::Document) }
  let(:mock_tag099_a) { instance_spy(Nokogiri::XML::Element, content: 'C0001') }
  let(:mock_log_out) { instance_spy(File) }
  let(:params) { Aspace2alma::ItemParams.new(mock_doc, mock_tag099_a, mock_log_out, nil) }
  let(:mock_top_container) { instance_spy(Aspace2alma::TopContainer) }
end

RSpec.shared_context 'with container data' do
  let(:container_json) do
    {
      'type' => 'Box',
      'indicator' => '1',
      'barcode' => '32101012345678'
    }.to_json
  end

  let(:mock_container_data) do
    {
      'json' => container_json,
      'uri' => '/repositories/2/top_containers/1'
    }
  end

  let(:mock_api_response) do
    instance_spy(ArchivesSpace::Response,
                 parsed: {
                   'response' => {
                     'docs' => [mock_container_data]
                   }
                 })
  end
end

RSpec.describe Aspace2alma::ItemRecordConstructor do
  describe 'ItemRecordConstructor class' do
    include_context 'with common mocks'
    include_context 'with container data'

    before do
      # Create a test CSV file
      FileUtils.mkdir_p('spec/fixtures')

      # Mock TopContainer class
      allow(Aspace2alma::TopContainer).to receive(:new).and_return(mock_top_container)
      allow(mock_top_container).to receive_messages(valid?: true, item_record: '<item>test</item>')

      # Mock logging
      allow(mock_log_out).to receive(:puts)

      # Mock MARC document operations
      mock_xpath_result = instance_spy(Nokogiri::XML::NodeSet)
      mock_last_element = instance_spy(Nokogiri::XML::Element)
      allow(mock_doc).to receive(:xpath).and_return(mock_xpath_result)
      allow(mock_xpath_result).to receive(:last).and_return(mock_last_element)
      allow(mock_last_element).to receive(:next=)
    end

    describe '#initialize' do
      it 'sets the client' do
        expect(constructor.client).to eq(mock_client)
      end
    end

    describe '#construct_item_records' do
      context 'when containers are found' do
        before do
          allow(mock_client).to receive(:get).and_return(mock_api_response)
        end

        it 'fetches containers from ArchivesSpace API' do
          allow(mock_client).to receive(:get)
            .with('repositories/2/top_containers/search',
                  query: { q: 'collection_uri_u_sstr:"/repositories/2/resources/123"' })
            .and_return(mock_api_response)

          constructor.construct_item_records(resource_uri, params)

          expect(mock_client).to have_received(:get)
            .with('repositories/2/top_containers/search',
                  query: { q: 'collection_uri_u_sstr:"/repositories/2/resources/123"' })
        end

        it 'processes valid containers' do
          allow(mock_top_container).to receive(:valid?).and_return(true)
          allow(mock_log_out).to receive(:puts).with('Created record for Box 1')

          constructor.construct_item_records(resource_uri, params)

          expect(mock_top_container).to have_received(:valid?)
          expect(mock_log_out).to have_received(:puts).with('Created record for Box 1')
        end

        it 'adds item records to MARC document' do
          allow(mock_top_container).to receive(:item_record).with('C0001').and_return('<item>test</item>')

          constructor.construct_item_records(resource_uri, params)

          expect(mock_top_container).to have_received(:item_record).with('C0001')
        end
      end

      context 'when no containers are found' do
        before do
          empty_response = instance_spy(ArchivesSpace::Response,
                                       parsed: { 'response' => { 'docs' => [] } })
          allow(mock_client).to receive(:get).and_return(empty_response)
        end

        it 'returns empty array without processing any containers' do
          result = constructor.construct_item_records(resource_uri, params)
          expect(result).to eq([])
          expect(mock_top_container).not_to have_received(:valid?)
        end
      end

      context 'when API returns nil' do
        before do
          allow(mock_client).to receive(:get).and_return(nil)
        end

        it 'handles API failure gracefully without side effects' do
          expect do
            result = constructor.construct_item_records(resource_uri, params)
            expect(result).to be_nil
          end.not_to raise_error
        end
      end

      context 'when container is invalid' do
        before do
          allow(mock_client).to receive(:get).and_return(mock_api_response)
          allow(mock_top_container).to receive(:valid?).and_return(false)
        end

        it 'skips invalid containers' do
          constructor.construct_item_records(resource_uri, params)

          expect(mock_top_container).not_to have_received(:item_record)
          expect(mock_log_out).not_to have_received(:puts)
        end
      end
    end

    describe '#construct_item_records integration test' do
      let(:real_client) { ArchivesSpace::Client.new(ArchivesSpace::Configuration.new(base_uri: 'https://example.com/staff/api')) }
      let(:real_constructor) do
        validator = instance_double(Aspace2alma::AlmaDuplicateBarcodeCheck, duplicate?: false)
        described_class.new(real_client, validator)
      end
      let(:resource_uri) { "/repositories/3/resources/1511" }
      let(:real_doc) { Aspace2alma::Resource.new(resource_uri, real_client, '', '').marc_xml }
      let(:real_tag099_a) { real_doc.at_xpath('//marc:datafield[@tag="099"]/marc:subfield[@code="a"]') }
      let(:real_log_out) { StringIO.new }
      let(:real_params) { Aspace2alma::ItemParams.new(real_doc, real_tag099_a, real_log_out, nil) }

      before do
        # Stub the ArchivesSpace API calls
        stub_request(:get, "https://example.com/staff/api/repositories/3/resources/marc21/1511.xml")
          .and_return(status: 200, body: file_fixture('aspace2alma/marc_1511.xml'))

        # Stub the containers API call (empty response means no containers found)
        stub_request(:get, "https://example.com/staff/api/repositories/3/top_containers/search?q=collection_uri_u_sstr:%22/repositories/3/resources/1511%22")
          .and_return(status: 200, body: "")
      end

      after do
        real_log_out.close unless real_log_out.closed?
      end

      it 'processes data without raising errors' do
        result = nil
        expect do
          result = real_constructor.construct_item_records(resource_uri, real_params)
        end.not_to raise_error

        # With empty container response, method should return nil (no containers found)
        expect(result).to be_nil

        # Verify the integration with real Resource and ArchivesSpace client works
        expect(real_tag099_a).not_to be_nil
        expect(real_tag099_a.content).to eq('MC001.01')
      end
    end

    describe 'private methods' do
      describe '#fetch_containers' do
        it 'constructs correct API endpoint' do
          allow(mock_client).to receive(:get)
            .with('repositories/2/top_containers/search',
                  query: { q: 'collection_uri_u_sstr:"/repositories/2/resources/123"' })

          constructor.send(:fetch_containers, resource_uri)

          expect(mock_client).to have_received(:get)
            .with('repositories/2/top_containers/search',
                  query: { q: 'collection_uri_u_sstr:"/repositories/2/resources/123"' })
        end
      end

      describe '#fetch_and_sort_containers' do
        context 'with multiple containers' do
          it 'sorts containers by indicator number' do
            first_container = { 'json' => { 'indicator' => '10' }.to_json }
            second_container = { 'json' => { 'indicator' => '2' }.to_json }
            unsorted_response = instance_spy(ArchivesSpace::Response,
                                            parsed: { 'response' => { 'docs' => [first_container, second_container] } })

            allow(mock_client).to receive(:get).and_return(unsorted_response)
            result = constructor.send(:fetch_and_sort_containers, resource_uri)

            # Should be sorted by numeric value: 2, then 10
            expect(JSON.parse(result[0]['json'])['indicator']).to eq('2')
            expect(JSON.parse(result[1]['json'])['indicator']).to eq('10')
          end
        end
      end
    end
  end

  describe Aspace2alma::ItemRecordUtils do
    include_context 'with common mocks'

    let(:alma_barcodes_set) { Set.new(['12345', '67890']) }

    describe '.extract_repository_id' do
      it 'extracts repository ID from resource URI' do
        result = described_class.extract_repository_id(resource_uri)
        expect(result).to eq('2')
      end
    end

    describe '.sort_containers_by_indicator' do
      it 'sorts containers by numeric indicator value' do
        containers = [
          { 'json' => { 'indicator' => '10' }.to_json },
          { 'json' => { 'indicator' => '2' }.to_json },
          { 'json' => { 'indicator' => '1' }.to_json }
        ]

        result = described_class.sort_containers_by_indicator(containers)

        indicators = result.map { |c| JSON.parse(c['json'])['indicator'] }
        expect(indicators).to eq(['1', '2', '10'])
      end
    end

    describe '.log_container_creation' do
      it 'logs container creation message' do
        json = { 'type' => 'Box', 'indicator' => '1' }
        described_class.log_container_creation(mock_log_out, json)

        expect(mock_log_out).to have_received(:puts).with('Created record for Box 1')
      end
    end

    describe '.add_item_record_to_doc' do
      let(:mock_xpath_result) { instance_spy(Nokogiri::XML::NodeSet) }
      let(:mock_last_element) { instance_spy(Nokogiri::XML::Element) }

      before do
        allow(mock_doc).to receive(:xpath).and_return(mock_xpath_result)
        allow(mock_xpath_result).to receive(:last).and_return(mock_last_element)
        allow(mock_top_container).to receive(:item_record).with('C0001').and_return('<item>test</item>')
        allow(mock_last_element).to receive(:next=).with('<item>test</item>')
      end

      it 'adds item record to MARC document' do
        described_class.add_item_record_to_doc(mock_doc, mock_top_container, mock_tag099_a)

        expect(mock_top_container).to have_received(:item_record).with('C0001')
        expect(mock_last_element).to have_received(:next=).with('<item>test</item>')
      end
    end
  end

  # Test the Params struct
  describe Aspace2alma::ItemParams do
    let(:mock_doc) { instance_spy(Nokogiri::XML::Document) }
    let(:mock_tag) { instance_spy(Nokogiri::XML::Element) }
    let(:mock_log) { instance_spy(File) }
    let(:barcode_set) { Set.new(['123', '456']) }

    describe 'initialization' do
      it 'creates a struct with all required fields' do
        params = described_class.new(mock_doc, mock_tag, mock_log, barcode_set)

        expect(params.doc).to eq(mock_doc)
        expect(params.tag099_a).to eq(mock_tag)
        expect(params.log_out).to eq(mock_log)
        expect(params.alma_barcodes_set).to eq(barcode_set)
      end
    end

    describe 'field access' do
      let(:params) { described_class.new(mock_doc, mock_tag, mock_log, nil) }

      it 'allows reading and writing alma_barcodes_set' do
        expect(params.alma_barcodes_set).to be_nil

        params.alma_barcodes_set = barcode_set
        expect(params.alma_barcodes_set).to eq(barcode_set)
      end
    end
  end
end
