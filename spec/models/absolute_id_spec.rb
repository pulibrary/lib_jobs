# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AbsoluteId, type: :model do
  let(:barcode) { '32101103191142' }
  let(:check_digit) { barcode.last }
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
    }.to_json
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
  let(:synchronize_status) { 'never synchronized' }
  let(:synchronized_at) { nil }
  let(:model_attributes) do
    {
      value: barcode,
      check_digit: check_digit,
      container: "1",
      location: location,
      container_profile: container_profile.to_json,
      repository: repository.to_json,
      resource: resource.to_json,
      index: 0,
      synchronize_status: synchronize_status,
      synchronized_at: synchronized_at
    }
  end
  let(:absolute_id) do
    described_class.new(model_attributes)
  end

  describe '#barcode' do
    context 'when using a blank barcode' do
      let(:barcode) { '' }

      it 'ensures that the barcode is present' do
        expect { absolute_id.barcode }.to raise_error(AbsoluteIds::InvalidBarcodeError, 'Barcode values cannot be blank')
      end
    end
  end

  describe '#valid?' do
    context 'when using a barcode with an invalid check digit' do
      let(:check_digit) { '9' }
      xit 'ensures that only barcodes with valid check digits are used to build the model' do
        expect(absolute_id).not_to be_valid
        expect(absolute_id.errors.full_messages).to eq(['Check digit Please specify a ID with valid check digit using the Luhn algorithm (please see: https://github.com/topics/luhn-algorithm?l=ruby)'])
      end
    end

    context 'with a duplicate index' do
      let(:absolute_id1) do
        described_class.create(model_attributes)
      end

      before do
        absolute_id1
      end

      xit 'ensures that no duplication indices for the same Location and ContainerProfiles are used to build the model' do
        expect(absolute_id).not_to be_valid
        expect(absolute_id.errors.full_messages.length).to eq(1)
        expect(absolute_id.errors.full_messages.first).to include('Duplicate index 0 for the AbID')
      end
    end
  end

  describe '#synchronize_status' do
    context 'when the synchronize_status attribute is blank' do
      let(:synchronize_status) { nil }

      context 'when the last synchronization time attribute is blank' do
        let(:synchronized_at) { nil }

        it 'returns unsynchronized' do
          expect(absolute_id.synchronize_status).to eq('unsynchronized')
        end
      end

      context 'when the last synchronization time attribute is present' do
        let(:synchronized_at) { DateTime.current }

        it 'returns synchronized' do
          expect(absolute_id.synchronize_status).to eq('synchronized')
        end
      end
    end
  end

  describe '#synchronize_status_color' do
    context 'when the last synchronization attempt failed' do
      let(:synchronize_status) { 'synchronization failed' }

      it 'returns the color red' do
        expect(absolute_id.synchronize_status_color).to eq('red')
      end
    end

    context 'when the last synchronization attempt has not finished' do
      let(:synchronize_status) { 'synchronizing' }

      it 'returns the color yellow' do
        expect(absolute_id.synchronize_status_color).to eq('yellow')
      end
    end
  end

  describe '#local_prefixes' do
    let(:location) do
      {
        "building": "Seeley G. Mudd Manuscript Library",
        "classification": "mudd",
        "create_time": "2021-01-22T22:29:47Z",
        "created_by": "admin",
        "external_ids": [],
        "functions": [],
        "jsonmodel_type": "location",
        "last_modified_by": "admin",
        "lock_version": 0,
        "system_mtime": "2021-01-22T22:29:47Z",
        "title": "Seeley G. Mudd Manuscript Library [mudd]",
        "uri": "/locations/23649",
        "user_mtime": "2021-01-22T22:29:47Z"
      }.to_json
    end

    it 'accesses the location prefixes' do
      expect(absolute_id.local_prefixes).to be_a(Hash)
      expect(absolute_id.local_prefixes).to include(
        "Mudd OS Extra height" => "XH",
        "Mudd OS Extra height, depth" => "XHD",
        "Mudd OS depth" => "DO",
        "Mudd OS height" => "H",
        "Mudd OS length" => "LO",
        "Mudd OS open" => "O",
        "Mudd Oversize folder" => "C",
        "Mudd ST half-manuscript" => "S",
        "Mudd ST manuscript" => "S",
        "Mudd ST other" => "S",
        "Mudd ST records center" => "S"
      )
    end

    context 'when the location attribute is a String' do
      let(:location) { 'mudd' }

      it 'accesses the location prefixes' do
        expect(absolute_id.local_prefixes).to be_a(Hash)
        expect(absolute_id.local_prefixes).to include(
          "Mudd OS Extra height" => "XH",
          "Mudd OS Extra height, depth" => "XHD",
          "Mudd OS depth" => "DO",
          "Mudd OS height" => "H",
          "Mudd OS length" => "LO",
          "Mudd OS open" => "O",
          "Mudd Oversize folder" => "C",
          "Mudd ST half-manuscript" => "S",
          "Mudd ST manuscript" => "S",
          "Mudd ST other" => "S",
          "Mudd ST records center" => "S"
        )
      end
    end
  end
end
