# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AbsoluteIds::LocationsController do
  describe '#index' do
    it 'returns all available locations as JSON' do
      stub_aspace_login
      stub_locations

      get :index, format: :json

      expect(response).to be_success
      json = JSON.parse(response.body)
      expect(json.length).to eq 26
      location = json[0]
      expect(location).to eq(
        {
          'create_time' => '2021-01-22T22:29:46Z',
          'id' => '23640',
          'lock_version' => 0,
          'system_mtime' => '2021-01-22T22:29:47Z',
          'uri' => '/locations/23640',
          'user_mtime' => '2021-01-22T22:29:46Z',
          'area' => 'Annex B',
          'barcode' => nil,
          'building' => 'Annex',
          'classification' => 'anxb',
          'external_ids' => [],
          'floor' => nil,
          'functions' => [],
          'room' => nil,
          'temporary' => nil
        }
      )
    end

    context 'when authorizing via a bearer token' do
      it 'skips forgery' do
        allow(controller).to receive(:verify_authenticity_token)
        stub_aspace_login
        stub_locations

        request.headers['Authorization'] = 'Bearer 123'
        get :index, format: :json

        expect(controller).not_to have_received(:verify_authenticity_token)
      end
    end
  end
end
