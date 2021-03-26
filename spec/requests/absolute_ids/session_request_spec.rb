# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "AbsoluteIds::Session", type: :request do
<<<<<<< HEAD
  let(:user) { create(:user) }
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

=======
>>>>>>> [WIP] Refactoring ApplicationJobs and implementing support for the generation of barcodes without AbIDs
  describe "POST /absolute-ids/sessions" do
    xit "renders all the absolute identifiers" do
      post "/absolute-ids/sessions"
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
<<<<<<< HEAD
=======
        let(:user) do
          User.create(email: 'user@localhost')
        end

>>>>>>> [WIP] Refactoring ApplicationJobs and implementing support for the generation of barcodes without AbIDs
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

<<<<<<< HEAD
=======
        before do
          user
        end

        after do
          user.destroy
        end

>>>>>>> [WIP] Refactoring ApplicationJobs and implementing support for the generation of barcodes without AbIDs
        it "denies the request" do
          post "/absolute-ids/sessions", headers: headers, params: params

          expect(response.forbidden?).to be true
        end
      end

      context "when the client does not pass a user ID" do
<<<<<<< HEAD
=======
        let(:user) do
          User.create(email: 'user@localhost')
        end

>>>>>>> [WIP] Refactoring ApplicationJobs and implementing support for the generation of barcodes without AbIDs
        let(:headers) do
          {
            "Accept" => "application/json",
            "Authorization" => "Bearer #{user.token}"
          }
        end

<<<<<<< HEAD
=======
        before do
          user
        end

        after do
          user.destroy
        end

>>>>>>> [WIP] Refactoring ApplicationJobs and implementing support for the generation of barcodes without AbIDs
        it "denies the request" do
          post "/absolute-ids/sessions", headers: headers

          expect(response.forbidden?).to be true
        end
      end

      context "when the client is authenticated" do
<<<<<<< HEAD
=======
        let(:user) do
          create(:user)
        end

>>>>>>> [WIP] Refactoring ApplicationJobs and implementing support for the generation of barcodes without AbIDs
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
            allow(LibJobs::ArchivesSpace::Client).to receive(:source).and_return(client)
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
      end
    end
  end
end
