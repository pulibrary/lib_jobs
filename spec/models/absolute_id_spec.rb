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
      value: barcode,
      check_digit: check_digit,
      container: "1",
      location: location.to_json,
      container_profile: container_profile.to_json,
      repository: repository.to_json,
      resource: resource.to_json,
      index: 0
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
end
