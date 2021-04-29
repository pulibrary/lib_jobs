# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AbsoluteIds::ImportJob, type: :job do
  let(:user) do
    create(:user)
  end

  describe '.perform_now' do
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
    let(:sequence_entry) do
      {
        prefix: prefix,
        index: index,
        call_number: ead_id,
        container_indicator: container_indicator,
        repo_code: repo_code,
        barcode: barcode,
        email: 'user@princeton.edu'
      }
    end
    let(:ead_id) { 'C1509' }
    let(:container_indicator) { '13' }
    let(:index) { container_indicator }
    let(:prefix) { 'B' }
    let(:repository_id) { '3' }
    let(:resource_id) { '4188' }
    let(:repo_code) { 'mss' }
    let(:barcode) { '32101080598434' }
    let(:email) { 'user@princeton.edu' }

    before do
      stub_aspace_login
      stub_repositories
      stub_locations
      stub_container_profiles

      # stub_resource_find_by_id(repository_id: '3', identifier: ead_id, resource_id: '4')

      stub_top_containers(ead_id: 'ABID001', repository_id: repository_id)
      stub_top_container(repository_id: 4, top_container_id: '118112')

      #
      stub_location(location_id: 23_640)
      stub_top_containers(ead_id: ead_id, repository_id: repository_id)
      stub_resource(resource_id: resource_id, repository_id: repository_id)
      stub_resource_find_by_id(repository_id: repository_id, identifier: ead_id, resource_id: resource_id)
      stub_repository(repository_id: repository_id)

      described_class.perform_now(sequence_entry)
    end

    it 'created and persists a new AbsoluteId record' do
      expect(AbsoluteId.all).not_to be_empty
      expect(AbsoluteId.last.value).to eq(barcode)

      expect(AbsoluteId.last.location).to include(
        {
          id: "23648",
          lock_version: 0,
          uri: "/locations/23648",
          area: "Manuscripts",
          building: "Firestone Library",
          classification: "mss",
          room: "Vault",
          temporary: nil
        }
      )
      expect(AbsoluteId.last.container_profile).to include(
        {
          id: "3",
          lock_version: 92_585,
          uri: "/container_profiles/3",
          name: "NBox"
        }
      )
      expect(AbsoluteId.last.repository).to include(
        {
          id: "3",
          uri: "/repositories/3"
        }
      )
      expect(AbsoluteId.last.resource).to include(
        {
          id: "4188",
          lock_version: 1,
          uri: "/repositories/3/resources/4188",
          title: "AbID Testing Resource #1",
          level: "collection"
        }
      )
      expect(AbsoluteId.last.container).to include(
        {
          id: "118103",
          lock_version: 1,
          uri: "/repositories/4/top_containers/118103",
          indicator: "13",
          type: "box"
        }
      )
    end
  end
end
