# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "AbsoluteIds::Session", type: :request do
  let(:user) { create(:user) }
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
  let(:repository_id) { '4' }
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
    JSON.parse(container_fixture)
  end
  let(:absolute_id1) do
    create(
           :absolute_id,
           value: "32101103191142",
           location: location.to_json,
           container_profile: container_profile.to_json,
           repository: repository.to_json,
           resource: resource.to_json,
           container: container.to_json
         )
  end
  let(:absolute_id2) do
    create(
           :absolute_id,
           value: "32101103191159",
           location: location.to_json,
           container_profile: container_profile.to_json,
           repository: repository.to_json,
           resource: resource.to_json,
           container: container.to_json
         )
  end
  let(:batch) do
    create(:absolute_id_batch, absolute_ids: [absolute_id1, absolute_id2])
  end
  let(:session) do
    create(:absolute_id_session, batches: [batch], user: user)
  end
  describe "GET /absolute-ids/sessions" do
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

    let(:absolute_id1) do
      create(:absolute_id, value: "32101103191142")
    end
    let(:absolute_id2) do
      create(:absolute_id, value: "32101103191159")
    end
    let(:batch) do
      create(:absolute_id_batch, absolute_ids: [absolute_id1, absolute_id2])
    end
    let(:session) do
      create(:absolute_id_session, batches: [batch], user: user)
    end
    let(:sessions) do
      [
        session
      ]
    end

    before do
      sessions
    end

    it "renders all the absolute identifiers for all batches in the sessions" do
      get "/absolute-ids", headers: headers, params: params

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
      expect(batch_json).to include("absolute_ids")

      ab_ids_json = batch_json["absolute_ids"]
      expect(ab_ids_json.length).to eq(2)

      expect(ab_ids_json.first).to include("barcode")
      barcode1_json = ab_ids_json.first["barcode"]
      expect(barcode1_json).to include("value" => "32101103191142")

      barcode2_json = ab_ids_json.last["barcode"]
      expect(barcode2_json).to include("value" => "32101103191159")
    end

    context "when the client passes an invalid JSON Web Token" do
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

      it "denies the request" do
        post "/absolute-ids/sessions", headers: headers, params: params

        expect(response.forbidden?).to be true
      end
    end
  end

  describe "GET /absolute-ids/sessions/:session_id" do
    let(:params) do
      {
        user: { id: user.id }
      }
    end
    let(:json_headers) do
      {
        "Accept" => "application/json",
        "Authorization" => "Bearer #{user.token}"
      }
    end

    before do
      session
    end

    it "renders all the absolute identifiers for all batches in the session" do
      get "/absolute-ids/sessions/#{session.id}", headers: json_headers, params: params

      expect(response.content_type).to eq("application/json")
      expect(response.body).not_to be_empty
      json_response = JSON.parse(response.body)

      expect(json_response).to be_a(Hash)
      expect(json_response).not_to be_empty

      expect(json_response).to include("id" => session.id)
      expect(json_response).to include("label" => session.label)
      expect(json_response).to include("batches")
      expect(json_response["batches"]).not_to be_empty

      batch_response = json_response["batches"].last
      expect(batch_response).to include("id" => batch.id)
      expect(batch_response).to include("label" => batch.label)
      expect(batch_response).to include("absolute_ids")

      ab_ids_json = batch_response["absolute_ids"]
      expect(ab_ids_json.length).to eq(2)

      expect(ab_ids_json.first).to include("barcode")
      barcode1_json = ab_ids_json.first["barcode"]
      expect(barcode1_json).to include("value" => "32101103191142")

      barcode2_json = ab_ids_json.last["barcode"]
      expect(barcode2_json).to include("value" => "32101103191159")
    end

    context "when the client passes an invalid JSON Web Token" do
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

      it "denies the request" do
        post "/absolute-ids/sessions", headers: headers, params: params

        expect(response.forbidden?).to be true
      end
    end

    context "when requesting a CSV report" do
      let(:headers) do
        {
          "Accept" => "text/csv",
          "Authorization" => "Bearer #{user.token}"
        }
      end

      it 'generates the CSV report for all batches within the session' do
        get "/absolute-ids/sessions/#{session.id}", headers: headers, params: params
        expect(response.body).not_to be_empty
        report = CSV.parse(response.body)

        expect(report.to_a.length).to eq(3)
        expect(report.to_a.first).to eq(["ID", "AbID", "User", "Barcode", "Location", "Container Profile", "Repository", "Call Number", "Box Number", "Status", "Last Synchronized At"])
        expect(report.to_a[1]).to include(
           "P-000000",
           "user@locahost.localdomain",
           "32101103191142",
           "Annex B",
           "Elephant size box",
           "University Archives",
           "AbID Testing Resource #1",
           "12",
           "unsynchronized"
         )

        expect(report.to_a.last).to include(
           "P-000000",
           "user@locahost.localdomain",
           "32101103191159",
           "Annex B",
           "Elephant size box",
           "University Archives",
           "AbID Testing Resource #1",
           "12",
           "unsynchronized"
         )
      end
    end
  end

  describe "POST /absolute-ids/sessions" do
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
      let(:container) { '13' }
      let(:params) do
        {
          user: {
            id: user.id
          },
          batches: [
            absolute_id: {
              barcode: barcode,
              container: container,
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

        it "denies the request" do
          post "/absolute-ids/sessions", headers: headers, params: params

          expect(response.forbidden?).to be true
        end
      end

      context "when the client does not pass a user ID" do
        let(:headers) do
          {
            "Accept" => "application/json",
            "Authorization" => "Bearer #{user.token}"
          }
        end

        it "denies the request" do
          post "/absolute-ids/sessions", headers: headers

          expect(response.forbidden?).to be true
        end
      end

      context "when the client is authenticated" do
        let(:headers) do
          {
            "Accept" => "application/json",
            "Authorization" => "Bearer #{user.token}"
          }
        end

        context "and requests multiple batches of AbIDs linked to ArchivesSpace records" do
          let(:source) { 'aspace' }
          let(:barcode) { '32101103191142' }
          let(:client) do
            stub_aspace_resource(repository_id: repository_id, resource_id: resource_id, ead_id: ead_id)
          end

          before do
            stub_location(location_id: '23640')
            stub_top_containers(ead_id: 'ABID001', repository_id: repository_id)
            stub_resource_find_by_id(repository_id: repository_id, identifier: '4188', resource_id: resource_id)
            stub_repository(repository_id: repository_id)
            stub_resource(repository_id: repository_id, resource_id: resource_id)
            stub_aspace_login
          end

          it "generates a new Ab. ID with the new size and uses the starting code" do
            post "/absolute-ids/sessions", headers: headers, params: params

            expect(response).to redirect_to(absolute_ids_path(format: :json))
            expect(AbsoluteId.all).not_to be_empty
            expect(AbsoluteId.last.barcode).to be_an(AbsoluteIds::Barcode)
            expect(AbsoluteId.last.barcode.value).to eq(barcode)
          end
        end

        context "and requests multiple batches of AbIDs linked to MARC records" do
          let(:source) { 'marc' }
          let(:barcode) { '32101103191159' }
          let(:container_profile) do
            "Elephant size box"
          end
          let(:location) do
            "Annex B"
          end
          let(:repository) do
            "University Archives"
          end
          it "generates a new Ab. ID with the new size and uses the starting code" do
            post "/absolute-ids/sessions", headers: headers, params: params

            expect(response).to redirect_to(absolute_ids_path(format: :json))
            expect(AbsoluteId.all).not_to be_empty
            expect(AbsoluteId.last.barcode).to be_an(AbsoluteIds::Barcode)
            expect(AbsoluteId.last.barcode.value).to eq(barcode)
            expect(AbsoluteId.last.location).to eq(location)
            expect(AbsoluteId.last.container_profile).to eq(container_profile)
            expect(AbsoluteId.last.repository).to eq(repository)
          end
        end

        context "when the client passes invalid parameters" do
          let(:headers) do
            {
              "Accept" => "application/json",
              "Authorization" => "Bearer #{user.token}"
            }
          end
          let(:barcode) { '32101103191159' }
          let(:container_profile) do
            "Elephant size box"
          end
          let(:location) do
            "Annex B"
          end
          let(:repository) do
            "University Archives"
          end
          let(:resource_id) { '4188' }
          let(:container) { '13' }
          let(:source) { 'aspace' }
          let(:params) do
            {
              user: {
                id: user.id
              },
              batches: [
                absolute_id: {
                  barcode: barcode,
                  container: container,
                  container_profile: container_profile,
                  location: location,
                  repository: repository,
                  resource: resource_id
                },
                barcodes: [
                  'invalid'
                ],
                batch_size: 1,
                source: source,
                valid: false
              ]
            }
          end
          let(:logger) { instance_double(ActiveSupport::Logger) }

          before do
            allow(logger).to receive(:warn)
            allow(logger).to receive(:info)
            allow(Rails).to receive(:logger).and_return(logger)
          end

          it "returns an error response status and logs the error" do
            post "/absolute-ids/sessions", headers: headers, params: params

            expect(response.status).to eq(302)
            expect(logger).to have_received(:warn).with(/Failed to create the Absolute ID/)
          end
        end
      end
    end
  end
end
