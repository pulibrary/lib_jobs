# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Barcodes::Session", type: :request do
  describe "POST /barcodes/sessions" do
    xit "renders all the absolute identifiers" do
      post "/barcodes/sessions"
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

        after do
          user.destroy
        end

        it "denies the request" do
          post "/barcodes/sessions", headers: headers, params: params

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

        after do
          user.destroy
        end

        it "denies the request" do
          post "/barcodes/sessions", headers: headers

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

        context "and requests multiple batches of AbIDs linked to ArchivesSpace records" do
          let(:source) { 'aspace' }
          let(:barcode) { '32101103191142' }

          before do
            stub_aspace_resource(repository_id: repository_id, resource_id: resource_id, ead_id: ead_id)
          end

          it "generates a new Ab. ID with the new size and uses the starting code" do
            post "/barcodes/sessions", headers: headers, params: params

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
            post "/barcodes/sessions", headers: headers, params: params

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
