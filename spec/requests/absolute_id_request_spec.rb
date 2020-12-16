# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "AbsoluteIds", type: :request do
  describe "GET /absolute-ids/:value" do
    let(:absolute_id) do
      AbsoluteId.create
    end

    before do
      allow(AbsoluteId).to receive(:find).and_return(absolute_id)
    end

    after do
      AbsoluteId.all.each(&:delete)
    end

    xit "renders an existing absolute identifier" do
      get "/absolute-ids/#{absolute_id.value}"
      # Pending
    end

    context "when requesting a JSON representation" do
      let(:headers) do
        {
          "ACCEPT" => "application/json"
        }
      end

      it "renders an existing absolute identifier" do
        get "/absolute-ids/#{absolute_id.value}", headers: headers

        expect(response.content_type).to eq("application/json")
        expect(response.body).not_to be_empty
        json_response = JSON.parse(response.body)

        expect(json_response).to be_an(Hash)

        expect(json_response).to include("check_digit" => 0)
        expect(json_response).to include("digits" => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        expect(json_response).to include("integer" => 0)
        expect(json_response).to include("valid" => true)
        expect(json_response).to include("value" => "00000000000000")
      end
    end
  end

  describe "GET /absolute-ids/" do
    let(:absolute_id1) do
      AbsoluteId.create
    end

    let(:absolute_id2) do
      AbsoluteId.create
    end

    let(:absolute_ids) do
      [
        absolute_id1,
        absolute_id2
      ]
    end

    before do
      allow(AbsoluteId).to receive(:all).and_return(absolute_ids)
    end

    after do
      AbsoluteId.all.each(&:delete)
    end

    xit "renders all the absolute identifiers" do
      get "/absolute-ids/"
      # Pending
    end

    context "when requesting a JSON representation" do
      let(:headers) do
        {
          "ACCEPT" => "application/json"
        }
      end

      it "renders all the absolute identifiers" do
        get "/absolute-ids/", headers: headers

        expect(response.content_type).to eq("application/json")
        expect(response.body).not_to be_empty
        json_response = JSON.parse(response.body)

        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(2)

        expect(json_response.first).to be_a(Hash)
        expect(json_response.first).to include("check_digit" => 0)
        expect(json_response.first).to include("digits" => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        expect(json_response.first).to include("integer" => 0)
        expect(json_response.first).to include("valid" => true)
        expect(json_response.first).to include("value" => "00000000000000")

        expect(json_response.last).to be_a(Hash)
        expect(json_response.last).to include("check_digit" => 9)
        expect(json_response.last).to include("digits" => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 9])
        expect(json_response.last).to include("integer" => 19)
        expect(json_response.last).to include("valid" => true)
        expect(json_response.last).to include("value" => "00000000000019")
      end
    end
  end

  describe "POST /absolute-ids/" do
    after do
      AbsoluteId.all.each(&:delete)
    end

    xit "renders all the absolute identifiers" do
      post "/absolute-ids/"
      # Pending
    end

    context "when requesting a JSON representation" do
      let(:headers) do
        {
          "ACCEPT" => "application/json"
        }
      end

      it "renders all the absolute identifiers" do
        expect(AbsoluteId.all).to be_empty

        post "/absolute-ids/", headers: headers

        expect(response).to redirect_to(absolute_id_path(value: AbsoluteId.last.value, format: :json))
        follow_redirect!

        expect(response.content_type).to eq("application/json")
        expect(response.body).not_to be_empty
        json_response = JSON.parse(response.body)
        expect(json_response).to be_a(Hash)
        expect(json_response).to include("value" => "00000000000000")

        post "/absolute-ids/", headers: headers

        expect(response).to redirect_to(absolute_id_path(value: AbsoluteId.last.value, format: :json))
        follow_redirect!

        expect(response.content_type).to eq("application/json")
        expect(response.body).not_to be_empty
        json_response = JSON.parse(response.body)
        expect(json_response).to be_a(Hash)
        expect(json_response).to include("value" => "00000000000019")
      end
    end
  end
end
