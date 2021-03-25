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
      container: "1",
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
        expect(children.length).to eq(10)
        #expect(children.length).to eq(6)
        #expect(children.length).to eq(11)

        expect(children[0].name).to eq("barcode")
        expect(children[0]['type']).to be nil
        expect(children[0].content).not_to be_empty

        expect(children[1].name).to eq("container_profile")
        expect(children[1]['type']).to be nil
        expect(children[1].content).not_to be_empty

        expect(children[2].name).to eq("created_at")
        expect(children[2]['type']).to eq("time")
        expect(children[2].content).not_to be_empty

        expect(children[3].name).to eq("id")
        expect(children[3]['type']).to eq "integer"
        expect(children[3].content).to eq("0")

        expect(children[4].name).to eq("location")
        expect(children[4]['type']).to be nil
        expect(children[4].content).not_to be_empty

        expect(children[5].name).to eq("size")
        expect(children[5]['type']).to eq "string"
        expect(children[5].content).to eq("P")

        expect(children[6].name).to eq("repository")
        expect(children[6]['type']).to be nil
        expect(children[6].content).not_to be_empty

        expect(children[7].name).to eq("resource")
        expect(children[7]['type']).to be nil
        expect(children[7].content).not_to be_empty

        expect(children[8].name).to eq("synchronize_status")
        expect(children[8]['type']).to eq "string"
        expect(children[8].content).to eq("never synchronized")

        expect(children[9].name).to eq("updated_at")
        expect(children[9]['type']).to eq("time")
        expect(children[9].content).not_to be_empty

        #expect(children[1].name).to eq("created_at")
        #expect(children[1]['type']).to eq("time")

        expect(children[1].name).to eq("container")
        expect(children[1]['type']).to be nil
        expect(children[1].content).not_to be_empty

        # expect(children[2].name).to eq("container_profile")
        # expect(children[2]['type']).to be nil
        # expect(children[2].content).not_to be_empty

        expect(children[2].name).to eq("created_at")
        expect(children[2]['type']).to eq("time")
        expect(children[2].content).not_to be_empty

        expect(children[3].name).to eq("id")
        expect(children[3]['type']).to eq "integer"
        expect(children[3].content).to eq("0")

        expect(children[4].name).to eq("location")
        expect(children[4]['type']).to be nil
        expect(children[4].content).not_to be_empty

        expect(children[5].name).to eq("size")
        expect(children[5]['type']).to eq "string"
        expect(children[5].content).to eq("P")

        expect(children[6].name).to eq("repository")
        expect(children[6]['type']).to be nil
        expect(children[6].content).not_to be_empty

        expect(children[7].name).to eq("resource")
        expect(children[7]['type']).to be nil
        expect(children[7].content).not_to be_empty

        expect(children[8].name).to eq("synchronize_status")
        expect(children[8]['type']).to eq "string"
        expect(children[8].content).to eq("never synchronized")

        expect(children[9].name).to eq("updated_at")
        expect(children[9]['type']).to eq("time")
        expect(children[9].content).not_to be_empty
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

        expect(json_response.last).to include("batches")
        batches_json = json_response.last["batches"]

        expect(batches_json).not_to be_empty
        batch_json = batches_json.last

        expect(batch_json).to include("id")
        expect(batch_json).to include("label")
        expect(batch_json).to include("absolute_ids")

        absolute_ids = batch_json["absolute_ids"]
        expect(absolute_ids.length).to eq(2)

        expect(absolute_ids.first).to include("barcode")
        expect(absolute_ids.first["barcode"]).to include("value" => "32101103191142")

        expect(absolute_ids.last).to include("barcode")
        expect(absolute_ids.last["barcode"]).to include("value" => "32101103191159")

        expect(json_response.length).to eq(1)
        expect(json_response).not_to be_empty

        expect(json_response.first).to include("batches")
        batches_json = json_response.first["batches"]

        expect(batches_json).not_to be_empty
        batch_json = batches_json.last

        expect(batch_json).to include("id")
        expect(batch_json).to include("label")
        expect(batch_json).to include("absolute_ids")

        absolute_ids = batch_json["absolute_ids"]
        expect(absolute_ids.length).to eq(2)

        expect(absolute_ids.first).to include("barcode")
        expect(absolute_ids.first["barcode"]).to include("value" => "32101103191142")

        expect(absolute_ids.last).to include("barcode")
        expect(absolute_ids.last["barcode"]).to include("value" => "32101103191159")
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

          before do
            stub_aspace_resource(repository_id: repository_id, resource_id: resource_id, ead_id: ead_id)
          end

          it "generates a new Ab. ID with the new prefix and uses the starting code" do
            expect(AbsoluteId.all).to be_empty

            post "/absolute-ids/", headers: headers, params: params

            expect(response).to redirect_to(absolute_ids_path(format: :json))
            expect(AbsoluteId.all).not_to be_empty
            expect(AbsoluteId.first.barcode).to be_an(AbsoluteIds::Barcode)
            expect(AbsoluteId.first.barcode.value).to eq("32101103191142")
          end
        end
      end
    end
  end
end
