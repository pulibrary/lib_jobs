# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaBibNorm::AlmaBibNorm, type: :model do
  subject(:alma_bib_norm) { described_class.new }
  let(:success) do
    Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.job do
        xml.id "M7407373650006421"
        xml.name "PUL-BIBNorm - via API - Unprocessed Datasync 914 fields"
        xml.type "MANUAL"
      end
    end.to_xml
  end
  let(:error) do
    Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.web_service_result do
        xml.errorsExist true
        xml.errorList do
          xml.error do
            xml.errorCode "402215"
            xml.errorMessage "Invalid format for job_id. Value: 123456. Valid format: Job type prefix (S,M,O) followed by digits"
          end
        end
      end
    end.to_xml
  end
  let(:headers) do
    {
      'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'Content-Type' => 'application/xml;charset=UTF-8',
      'Accept' => 'application/xml',
      'User-Agent' => 'Faraday v1.0.1'
    }
  end

  describe "submit job to Alma API" do
    context "with a successful response" do
      before do
        stub_request(:post, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/jobs/M7407373650006421?apikey=#{LibJobs.config[:alma_api_key]}&op=run")
          .to_return(status: 200, body: success, headers:)
      end

      it "returns a response with a 200" do
        expect(alma_bib_norm.run).to be_truthy

        data_set = DataSet.last
        expect(data_set.category).to eq("PulBibNorm")
      end
    end

    context "with an unsuccessful response" do
      before do
        stub_request(:post, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/jobs/M7407373650006421?apikey=#{LibJobs.config[:alma_api_key]}&op=run")
          .to_return(status: 400, body: error, headers:)
      end

      it "returns a response wtih 400 and error messsage" do
        expect(alma_bib_norm.run).to be_falsey
        data_set = DataSet.last
        expect(data_set.category).to eq("PulBibNorm")
        expect(data_set.status).to eq(false)
        expect(data_set.data).to eq("Job failed with response code: 400, and body: Invalid format for job_id. Value: 123456. Valid format: Job type prefix (S,M,O) followed by digits")
      end
    end
  end
end
