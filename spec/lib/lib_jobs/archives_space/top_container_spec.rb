# frozen_string_literal: true
require 'rails_helper'

describe LibJobs::ArchivesSpace::TopContainer do
  subject(:top_container) do
    described_class.new(object_attributes.deep_symbolize_keys)
  end

  let(:fixture_file_path) do
    Rails.root.join('spec', 'fixtures', 'archives_space', 'top_container.json')
  end
  let(:fixture_json) do
    File.read(fixture_file_path)
  end
  let(:fixture_values) do
    JSON.parse(fixture_json)
  end
  let(:repository) { instance_double(LibJobs::ArchivesSpace::Repository) }

  let(:location_fixture_file_path) do
    Rails.root.join('spec', 'fixtures', 'archives_space', 'location.json')
  end
  let(:location_fixture_json) do
    File.read(fixture_file_path)
  end
  let(:location_fixture_values) do
    JSON.parse(fixture_json)
  end
  let(:location_attributes) do
    fixture_values.merge(
      {
        repository: repository
      }
    )
  end
  let(:location1) do
    'location1'
  end
  let(:location2) do
    'location2'
  end
  let(:container_locations) do
    [
      location1,
      location2
    ]
  end
  let(:object_attributes) do
    fixture_values.merge(
      {
        repository: repository,
        container_locations: container_locations
      }
    )
  end

  describe '.model_class_exists?' do
    it 'returns true' do
      expect(described_class.model_class_exists?).to be true
    end
  end

  describe '#to_params' do
    it 'generates the POST parameters' do
      expect(top_container.to_params).to include(
        active_restrictions: [],
        barcode: nil,
        collection: [
          {
            display_string: "AbID Testing Resource #1",
            identifier: "ABID001",
            ref: "/repositories/4/resources/4188"
          }
        ],
        container_locations: container_locations,
        exported_to_ils: nil,
        ils_holding_id: nil,
        ils_item_id: nil,
        indicator: "12",
        jsonmodel_type: "top_container",
        lock_version: 4,
        series: [],
        type: "box"
      )
    end

    context 'with Location attributes' do
      let(:location_fixture_file_path) do
        Rails.root.join('spec', 'fixtures', 'archives_space', 'location.json')
      end
      let(:location_fixture_json) do
        File.read(fixture_file_path)
      end
      let(:location_fixture_values) do
        JSON.parse(fixture_json)
      end
      let(:location_attributes) do
        fixture_values.merge(
          {
            repository: repository
          }
        )
      end
      let(:location1) do
        LibJobs::ArchivesSpace::Location.new(location_attributes.deep_symbolize_keys)
      end
      let(:location2) do
        LibJobs::ArchivesSpace::Location.new(location_attributes.deep_symbolize_keys)
      end

      it 'generates the POST parameters' do
        expect(top_container.to_params).to include(
          active_restrictions: [],
          barcode: nil,
          collection: [
            {
              display_string: "AbID Testing Resource #1",
              identifier: "ABID001",
              ref: "/repositories/4/resources/4188"
            }
          ],
          container_locations: [
            {
              jsonmodel_type: "container_location",
              ref: "/top_containers/118091",
              start_date: "2021-02-25",
              status: "current",
              system_mtime: "2021-03-10T15:43:35Z",
              user_mtime: "2021-03-10T15:43:35Z"
            },
            {
              jsonmodel_type: "container_location",
              ref: "/top_containers/118091",
              start_date: "2021-02-25",
              status: "current",
              system_mtime: "2021-03-10T15:43:35Z",
              user_mtime: "2021-03-10T15:43:35Z"
            }
          ],
          exported_to_ils: nil,
          ils_holding_id: nil,
          ils_item_id: nil,
          indicator: "12",
          jsonmodel_type: "top_container",
          lock_version: 4,
          series: [],
          type: "box"
        )
      end
    end
  end

  describe '#locations' do
    context 'with cached attributes' do
      let(:location1) do
        {
          _resolved: location_attributes
        }
      end
      let(:location2) do
        {
          _resolved: location_attributes
        }
      end

      it 'constructs Location objects' do
        expect(top_container.locations.length).to eq(2)
        expect(top_container.locations.first).to be_a(LibJobs::ArchivesSpace::Location)
        expect(top_container.locations.last).to be_a(LibJobs::ArchivesSpace::Location)
      end
    end

    context 'with invalid attributes' do
      let(:location1) do
        {
          invalid: location_attributes
        }
      end
      let(:location2) do
        {
          invalid: location_attributes
        }
      end

      it 'raises an error' do
        expect { top_container.locations }.to raise_error(ArgumentError, /Failed to construct a LibJobs::ArchivesSpace::TopContainer object/)
      end
    end
  end
end
