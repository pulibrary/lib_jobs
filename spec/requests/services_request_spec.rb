# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Services", type: :request do
  describe "GET /services/archivesspace" do
    before do
      stub_aspace_login
    end

    context "when requesting a JSON representation" do
      let(:headers) do
        {
          "Accept" => "application/json"
        }
      end

      it "renders an existing absolute identifier" do
        get "/services/archivesspace", headers: headers

        expect(response.status).to eq(200)
        expect(response.body).not_to be_empty
        json_response = JSON.parse(response.body)

        expect(json_response).to include("uri" => "https://aspace.test.org/staff/api")
      end

      context "when an error is encountered connecting to the ArchivesSpace API" do
        before do
          allow(LibJobs::ArchivesSpace::Client).to receive(:source).and_raise(ArchivesSpace::ConnectionError)
        end

        it "returns a 403 error" do
          get "/services/archivesspace", headers: headers

          expect(response.status).to eq(403)
          expect(response.body).to be_empty
        end
      end
    end
  end
end
