# frozen_string_literal: true
require 'rails_helper'

describe LibJobs::ArchivesSpace::Location do
  subject(:location) do
    described_class.new(location_attributes.deep_symbolize_keys)
  end

  let(:fixture_file_path) do
    Rails.root.join('spec', 'fixtures', 'archives_space', 'location.json')
  end
  let(:fixture_json) do
    File.read(fixture_file_path)
  end
  let(:fixture_values) do
    JSON.parse(fixture_json)
  end
  let(:repository) do
    instance_double(LibJobs::ArchivesSpace::Repository)
  end
  let(:location_attributes) do
    fixture_values.merge(
      {
        repository: repository
      }
    )
  end
  let(:start_date) do
    "2021-01-22"
  end
  let(:system_mtime) do
    "2021-01-22T22:29:47Z"
  end
  let(:user_mtime) do
    "2021-01-22T22:29:46Z"
  end

  describe '#to_container_ref' do
    let(:refs) do
      location.to_container_ref
    end

    it 'generates the Hash used to build API POST request parameters' do
      expect(refs).to include({
                                jsonmodel_type: 'container_location',
                                status: 'current',
                                start_date: start_date,
                                system_mtime: system_mtime,
                                user_mtime: user_mtime,
                                ref: "/locations/23640"
                              })
    end
  end
end
