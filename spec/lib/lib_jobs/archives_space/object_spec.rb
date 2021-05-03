# frozen_string_literal: true
require 'rails_helper'

describe LibJobs::ArchivesSpace::Object do
  subject(:archives_space_object) { described_class.new(object_attributes) }

  let(:client) { LibJobs::ArchivesSpace::Client.source }
  let(:id) { "4" }
  let(:uri) { "/repositories/#{id}" }
  let(:object_attributes) do
    {
      client: client,
      uri: uri
    }
  end

  describe '#base_uri' do
    it 'returns the URI from the API client' do
      expect(archives_space_object.base_uri).to eq('https://aspace.test.org/staff/api')
    end

    context 'when the client attribute is nil' do
      let(:client) { nil }

      it 'returns the URI from the API client' do
        expect(archives_space_object.base_uri).to eq('https://aspace.test.org/staff/api')
      end
    end
  end

  describe '#eql?' do
    let(:archives_space_object2) { described_class.new(object_attributes) }
    let(:object_attributes3) do
      {
        client: client,
        uri: "/repositories/5"
      }
    end
    let(:archives_space_object3) { described_class.new(object_attributes3) }

    it 'determines if two objects are equal' do
      expect(archives_space_object.eql?(archives_space_object2)).to be true
      expect(archives_space_object.eql?(archives_space_object3)).to be false
    end
  end
end
