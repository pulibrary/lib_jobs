# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AbsoluteIds::Serializers::AbsoluteIdXmlSerializer do
  subject(:serializer) do
    described_class.new(model)
  end

  let(:barcode) { '32101103191142' }
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
  let(:repository_id) { '4' }
  let(:resource_fixture_path) do
    Rails.root.join('spec', 'fixtures', 'archives_space', 'resource.json')
  end
  let(:resource_fixture) do
    File.read(resource_fixture_path)
  end
  let(:resource) do
    JSON.parse(resource_fixture)
  end
  let(:resource_id) { 'ABID001' }
  let(:container_fixture_path) do
    Rails.root.join('spec', 'fixtures', 'archives_space', 'top_container.json')
  end
  let(:container_fixture) do
    File.read(container_fixture_path)
  end
  let(:container) do
    JSON.parse(container_fixture)
  end
  let(:model_attributes) do
    {
      value: barcode,
      location: location.to_json,
      container_profile: container_profile.to_json,
      repository: repository.to_json,
      resource: resource.to_json,
      container: container.to_json,
      check_digit: '2',
      index: 0
    }
  end
  let(:model) { create(:absolute_id, **model_attributes) }

  describe '#serialize' do
    let(:fixture_path) do
      Rails.root.join('spec', 'fixtures', 'absolute_id.xml')
    end
    let(:fixture) do
      File.read(fixture_path)
    end
    let(:fixture_document) do
      Nokogiri::XML::Document.parse(fixture)
    end
    it 'builds an XML representation of the AbID' do
      expect(serializer.serialize).to be_a(String)

      serialized_document = Nokogiri::XML::Document.parse(serializer.serialize)
      expect(serialized_document.root.children.length).to eq(fixture_document.root.children.length)
      expect(serialized_document.root.children.map(&:name)).to eq(fixture_document.root.children.map(&:name))

      element_args = serialized_document.root.children.select { |c| c.is_a?(Nokogiri::XML::Element) }.map do |e|
        [e.name, e]
      end
      elements = Hash[element_args]
      fixture_element_args = fixture_document.root.children.select { |c| c.is_a?(Nokogiri::XML::Element) }.map do |e|
        [e.name, e]
      end
      fixture_elements = Hash[fixture_element_args]

      expect(elements[:barcode]).to eq(fixture_elements[:barcode])
      expect(elements[:container]).to eq(fixture_elements[:container])
      expect(elements[:container_profile]).to eq(fixture_elements[:container_profile])
      expect(elements[:id]).to eq(fixture_elements[:id])
      expect(elements[:label]).to eq(fixture_elements[:label])
      expect(elements[:location]).to eq(fixture_elements[:location])
      expect(elements[:size]).to eq(fixture_elements[:size])
      expect(elements[:repository]).to eq(fixture_elements[:repository])
      expect(elements[:resource]).to eq(fixture_elements[:resource])
      expect(elements[:synchronize_status]).to eq(fixture_elements[:synchronize_status])
    end
  end
end
