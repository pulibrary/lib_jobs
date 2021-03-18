# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "AbsoluteIds", type: :request do
  let(:barcode) { '32101103191142' }
  let(:repository_id) { '4' }
  let(:resource_id) { 'ABID001' }
  let(:container_profile) do
    {
      create_time: "2021-01-21T20:10:59Z",
      id: "2",
      lock_version: 873,
      system_mtime: "2021-01-25T05:10:46Z",
      uri: "/container_profiles/2",
      user_mtime: "2021-01-21T20:10:59Z",
      name: "Elephant size box",
      size: "P"
    }
  end
  let(:location) do
    {
      create_time: "2021-01-22T22:29:46Z",
      id: "23640",
      lock_version: 0,
      system_mtime: "2021-01-22T22:29:47Z",
      uri: "/locations/23640",
      user_mtime: "2021-01-22T22:29:46Z",
      area: "Annex B",
      barcode: nil,
      building: "Annex",
      classification: "anxb",
      external_ids: [],
      floor: nil,
      functions: [],
      room: nil,
      temporary: nil
    }
  end
  let(:resource_fixture_path) do
    Rails.root.join('spec', 'fixtures', 'archives_space', 'resource.json')
  end
  let(:resource_fixture) do
    File.read(resource_fixture_path)
  end
  let(:resource) do
    JSON.parse(resource_fixture)
  end
  let(:container_fixture_path) do
    Rails.root.join('spec', 'fixtures', 'archives_space', 'top_container.json')
  end
  let(:container_fixture) do
    File.read(container_fixture_path)
  end
  let(:container) do
    "1"
  end
  let(:repository) do
    {
      create_time: "2016-06-27T14:10:42Z",
      id: repository_id,
      lock_version: 1,
      system_mtime: "2021-01-22T22:20:30Z",
      uri: "/repositories/4",
      user_mtime: "2021-01-22T22:20:30Z",
      name: "University Archives",
      repo_code: "univarchives"
    }
  end
  let(:model_attributes) do
    {
      barcode: barcode,
      container: container,
      location: location.to_json,
      container_profile: container_profile.to_json,
      repository: repository.to_json,
      resource: resource.to_json
    }
  end
  describe "GET /absolute-ids/:value" do
    let(:absolute_id) do
      AbsoluteId.generate(**model_attributes)
    end

    xit "renders an existing absolute identifier" do
      get "/absolute-ids/#{absolute_id.value}"
      # Pending
    end

    context "when requesting a JSON representation" do
      let(:headers) do
        {
          "Accept" => "application/json"
        }
      end

      before do
        absolute_id if AbsoluteId.all.empty?
      end

      it "renders an existing absolute identifier" do
        get "/absolute-ids/#{absolute_id.value}", headers: headers

        expect(response.content_type).to eq("application/json")
        expect(response.body).not_to be_empty
        json_response = JSON.parse(response.body)

        expect(json_response).to be_an(Hash)

        expect(json_response).to include("created_at")
        expect(json_response["created_at"]).not_to be_empty
        expect(json_response).to include("updated_at")
        expect(json_response["updated_at"]).not_to be_empty
        expect(json_response).to include("id" => 0)
        expect(json_response).to include("size" => "P")
        expect(json_response).to include("synchronize_status" => "never synchronized")
      end
    end

    context "when requesting a XML representation" do
      let(:headers) do
        {
          "Accept" => "application/xml"
        }
      end
      let(:container) do
        JSON.parse(container_fixture)
        container_fixture
      end

      before do
        absolute_id if AbsoluteId.all.empty?
      end

      it "renders an existing absolute identifier" do
        get "/absolute-ids/#{absolute_id.value}", headers: headers

        expect(response.content_type).to eq("application/xml")
        expect(response.body).not_to be_empty

        xml_document = Nokogiri::XML(response.body)
        expect(xml_document.root.name).to eq("absolute_id")
        children = xml_document.root.elements
        expect(children.length).to eq(11)

        expect(children[0].name).to eq("barcode")
        expect(children[0]['type']).to be nil
        expect(children[0].content).not_to be_empty

        expect(children[1].name).to eq("container")
        expect(children[1]['type']).to be nil
        expect(children[1].content).not_to be_empty

        expect(children[2].name).to eq("container_profile")
        expect(children[2]['type']).to be nil
        expect(children[2].content).not_to be_empty

        expect(children[3].name).to eq("created_at")
        expect(children[3]['type']).to eq("time")
        expect(children[3].content).not_to be_empty

        expect(children[4].name).to eq("id")
        expect(children[4]['type']).to eq "integer"
        expect(children[4].content).to eq("0")

        expect(children[5].name).to eq("location")
        expect(children[5]['type']).to be nil
        expect(children[5].content).not_to be_empty

        expect(children[6].name).to eq("size")
        expect(children[6]['type']).to eq "string"
        expect(children[6].content).to eq("P")
      end
    end
  end

  describe "GET /absolute-ids/" do
    let(:absolute_id1) do
      AbsoluteId.generate
    end

    let(:absolute_id2) do
      AbsoluteId.generate
    end

    let(:absolute_ids) do
      [
        absolute_id1,
        absolute_id2
      ]
    end

    before do
      absolute_ids
    end

    it "renders all the absolute identifiers" do
      get "/absolute-ids/"
      # Pending
    end

    context "when requesting a JSON representation" do
      let(:user) { create(:user) }
      let(:params) do
        {
          user: { id: user.id }
        }
      end
      let(:headers) do
        {
          "Accept" => "application/json",
          "Authorization" => "Bearer #{user.token}"
        }
      end
      let(:absolute_id1) { create(:absolute_id, value: '32101103191142') }
      let(:absolute_id2) { create(:absolute_id, value: '32101103191159') }
      let(:absolute_id_batch) { create(:absolute_id_batch, absolute_ids: [absolute_id1, absolute_id2], user: user) }
      let(:absolute_id_session) { create(:absolute_id_session, batches: [absolute_id_batch], user: user) }

      before do
        absolute_id_session
      end

      it "renders all the absolute identifiers" do
        get "/absolute-ids/", headers: headers, params: params

        expect(response.content_type).to eq("application/json")
        expect(response.body).not_to be_empty
        json_response = JSON.parse(response.body)

        expect(json_response).to be_an(Array)
        expect(json_response).not_to be_empty

        expect(json_response.first).to include("batches")
        batches_json = json_response.first["batches"]

        expect(batches_json).not_to be_empty
        batch_json = batches_json.first

        batch = AbsoluteId::Batch.first
        expect(batch_json).to include("id" => batch.id)
        expect(batch_json).to include("label" => batch.label)
        expect(batch_json).to include("table_data")

        table_json = batch_json["table_data"]
        expect(table_json.length).to eq(2)

        expect(table_json.first).to include("barcode" => "32101103191142")
        expect(table_json.last).to include("barcode" => "32101103191159")
      end
    end
  end

  describe "POST /absolute-ids/" do
    xit "renders all the absolute identifiers" do
      post "/absolute-ids/"
      # Pending
    end

    context "when requesting a JSON representation" do
      let(:headers) do
        {
          "Accept" => "application/json"
        }
      end
      let(:repository_id) { '4' }
      let(:ead_id) { 'ABID001' }
      let(:resource_id) { '4188' }
      let(:container_profile) do
        {
          create_time: "2021-01-21T20:10:59Z",
          id: "2",
          lock_version: 873,
          system_mtime: "2021-01-25T05:10:46Z",
          uri: "/container_profiles/2",
          user_mtime: "2021-01-21T20:10:59Z",
          name: "Elephant size box",
          prefix: "P"
        }
      end
      let(:location) do
        {
          create_time: "2021-01-22T22:29:46Z",
          id: "23640",
          lock_version: 0,
          system_mtime: "2021-01-22T22:29:47Z",
          uri: "/locations/23640",
          user_mtime: "2021-01-22T22:29:46Z",
          area: "Annex B",
          barcode: nil,
          building: "Annex",
          classification: "anxb",
          external_ids: [],
          floor: nil,
          functions: [],
          room: nil,
          temporary: nil
        }
      end
      let(:repository) do
        {
          create_time: "2016-06-27T14:10:42Z",
          id: repository_id,
          lock_version: 1,
          system_mtime: "2021-01-22T22:20:30Z",
          uri: "/repositories/4",
          user_mtime: "2021-01-22T22:20:30Z",
          name: "University Archives",
          repo_code: "univarchives"
        }
      end
      let(:params) do
        {
          user: {
            id: user.id
          },
          batches: [
            absolute_id: {
              barcode: barcode,
              container: "1",
              container_profile: container_profile,
              location: location,
              repository: repository,
              resource: resource_id
            },
            barcodes: [
              barcode
            ],
            batch_size: 1,
            source: source,
            valid: true
          ]
        }
      end

      context "when the client passes an invalid JSON Web Token" do
        let(:user) do
          User.create(email: 'user@localhost')
        end

        let(:headers) do
          {
            "Accept" => "application/json",
            "Authorization" => "Bearer invalid"
          }
        end

        let(:params) do
          {
            user: { id: user.id }
          }
        end

        before do
          user
        end

        it "denies the request" do
          post "/absolute-ids/", headers: headers, params: params

          expect(response.forbidden?).to be true
        end
      end

      context "when the client does not pass a user ID" do
        let(:user) do
          User.create(email: 'user@localhost')
        end

        let(:headers) do
          {
            "Accept" => "application/json",
            "Authorization" => "Bearer #{user.token}"
          }
        end

        before do
          user
        end

        it "denies the request" do
          post "/absolute-ids/", headers: headers

          expect(response.forbidden?).to be true
        end
      end

      context "when the client is authenticated" do
        let(:user) do
          create(:user)
        end

        let(:headers) do
          {
            "Accept" => "application/json",
            "Authorization" => "Bearer #{user.token}"
          }
        end

        context "and requests a prefix and starting code" do
          let(:params) do
            {
              user: {
                id: user.id
              },
              batch: [
                absolute_id: {
                  barcode: "32101103191142",
                  container: "1",
                  container_profile: {
                    create_time: "2021-01-21T20:10:59Z",
                    id: "2",
                    lock_version: 873,
                    system_mtime: "2021-01-25T05:10:46Z",
                    uri: "/container_profiles/2",
                    user_mtime: "2021-01-21T20:10:59Z",
                    name: "Elephant size box",
                    prefix: "P"
                  },
                  location: {
                    create_time: "2021-01-22T22:29:46Z",
                    id: "23640",
                    lock_version: 0,
                    system_mtime: "2021-01-22T22:29:47Z",
                    uri: "/locations/23640",
                    user_mtime: "2021-01-22T22:29:46Z",
                    area: "Annex B",
                    barcode: nil,
                    building: "Annex",
                    classification: "anxb",
                    external_ids: [],
                    floor: nil,
                    functions: [],
                    room: nil,
                    temporary: nil
                  },
                  repository: {
                    create_time: "2016-06-27T14:10:42Z",
                    id: "4",
                    lock_version: 1,
                    system_mtime: "2021-01-22T22:20:30Z",
                    uri: "/repositories/4",
                    user_mtime: "2021-01-22T22:20:30Z",
                    name: "University Archives",
                    repo_code: "univarchives"
                  },
                  resource: "ABID001",
                  source: 'aspace'
                },
                barcodes: [
                  "32101103191142"
                ],
                batch_size: 1,
                valid: true
              ]
            }
          end
          let(:repository_id) { '4' }
          let(:ead_id) { 'ABID001' }
          let(:resource_id) { '4188' }
        end
      end
    end
  end
end
