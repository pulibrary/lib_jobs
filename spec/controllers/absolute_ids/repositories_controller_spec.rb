# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AbsoluteIds::RepositoriesController do
  describe '#index' do
    it 'returns all available locations as JSON' do
      stub_aspace_login
      stub_repositories

      get :index, format: :json

      json = JSON.parse(response.body)
      expect(json.length).to eq(3)
      expect(json[0]).to eq(
        {
          'create_time' => '2016-06-27T14:10:41Z',
          'id' => '3',
          'lock_version' => 2,
          'system_mtime' => '2021-01-22T22:19:27Z',
          'uri' => '/repositories/3',
          'user_mtime' => '2021-01-22T22:19:27Z',
          'name' => 'Public Policy Papers',
          'repo_code' => 'publicpolicy'
        }
      )
    end

    context 'when authorizing via a bearer token' do
      it 'skips forgery' do
        allow(controller).to receive(:verify_authenticity_token)
        stub_aspace_login
        stub_repositories

        request.headers['Authorization'] = 'Bearer 123'
        get :index, format: :json

        expect(controller).not_to have_received(:verify_authenticity_token)
      end
    end
  end
end
