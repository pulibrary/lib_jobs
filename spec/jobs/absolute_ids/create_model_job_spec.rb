# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AbsoluteIds::CreateModelJob, type: :job do
  describe '.polymorphic_perform_now' do
    let(:user) do
      create(:user)
    end
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
        id: "4",
        lock_version: 1,
        system_mtime: "2021-01-22T22:20:30Z",
        uri: "/repositories/4",
        user_mtime: "2021-01-22T22:20:30Z",
        name: "University Archives",
        repo_code: "univarchives"
      }
    end

    context 'when linking to ArchivesSpace resources' do
      let(:properties) do
        {
          barcode: "32101103191142",
          container: "1",
          container_profile: container_profile,
          location: location,
          repository: repository,
          resource: "ABID001",
          source: 'aspace',
          index: 0
        }
      end
      let(:repository_id) { '4' }
      let(:ead_id) { 'ABID001' }
      let(:resource_id) { '4188' }
      let(:source_client) do
        stub_aspace_resource(repository_id: repository_id, resource_id: resource_id, ead_id: ead_id)
      end

      before do
        allow(LibJobs::ArchivesSpace::Client).to receive(:source).and_return(source_client)

        described_class.polymorphic_perform_now(properties: properties, user_id: user.id)
      end

      it 'created and persists a new AbsoluteId record' do
        expect(AbsoluteId.all).not_to be_empty
        expect(AbsoluteId.last.value).to eq('32101103191142')

        expect(AbsoluteId.last.label).to include('P-00000')
        expect(AbsoluteId.last.container_profile).not_to be_empty
        expect(AbsoluteId.last.container_profile_object).not_to be_nil
        expect(AbsoluteId.last.container_profile_object.id).to eq('2')

        expect(AbsoluteId.last.location).not_to be_empty
        expect(AbsoluteId.last.location_object).not_to be_nil
        expect(AbsoluteId.last.location_object.id).to eq('23640')

        expect(AbsoluteId.last.repository).not_to be_empty
        expect(AbsoluteId.last.repository_object).not_to be_nil
        expect(AbsoluteId.last.repository_object.id).to eq('4')

        expect(AbsoluteId.last.resource).not_to be_empty
        expect(AbsoluteId.last.resource_object).not_to be_nil
        expect(AbsoluteId.last.resource_object.id).to eq('4188')
        expect(AbsoluteId.last.resource_object.uri).to eq("/repositories/4/resources/4188")
        expect(AbsoluteId.last.resource_object.ead_id).to eq("ABID001")
        expect(AbsoluteId.last.resource_object.title).to eq("AbID Testing Resource #1")

        expect(AbsoluteId.last.container).not_to be_empty
        expect(AbsoluteId.last.container_object).not_to be_nil
        expect(AbsoluteId.last.container_object.id).to eq('118092')
        expect(AbsoluteId.last.container_object.uri).to eq("/repositories/4/top_containers/118092")
        expect(AbsoluteId.last.container_object.type).to eq("box")
      end
    end

    context 'when linking to MARC resources' do
      let(:container_profile) { 'B' }
      let(:location) { 'mss' }
      let(:repository) { '' }
      let(:properties) do
        {
          barcode: "32101103191159",
          container: "1",
          container_profile: container_profile,
          location: location,
          repository: repository,
          resource: "10915154",
          source: 'marc',
          index: 0
        }
      end

      before do
        described_class.polymorphic_perform_now(properties: properties, user_id: user.id)
      end

      it 'created and persists a new AbsoluteId record' do
        expect(AbsoluteId.all).not_to be_empty
        expect(AbsoluteId.last.value).to eq('32101103191159')
        expect(AbsoluteId.last.label).to eq('B-000001')

        expect(AbsoluteId.last.container_profile).not_to be_empty
        expect(AbsoluteId.last.container_profile).to eq(container_profile)
        expect(AbsoluteId.last.container_profile_object).not_to be_nil
        expect(AbsoluteId.last.container_profile_object.to_h).to be_empty

        expect(AbsoluteId.last.location).to eq(location)
        expect(AbsoluteId.last.location_object).not_to be_nil
        expect(AbsoluteId.last.location_object.to_h).to be_empty

        expect(AbsoluteId.last.repository).to eq(repository)
        expect(AbsoluteId.last.repository_object).not_to be_nil
        expect(AbsoluteId.last.repository_object.to_h).to be_empty

        expect(AbsoluteId.last.resource).to eq('10915154')
        expect(AbsoluteId.last.resource_object).to be_an(OpenStruct)
        expect(AbsoluteId.last.resource_object.to_h).to be_empty
        expect(AbsoluteId.last.container).to eq('1')
        expect(AbsoluteId.last.container_object).to be_an(OpenStruct)
        expect(AbsoluteId.last.container_object.to_h).to be_empty
      end
    end
  end
end
