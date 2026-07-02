# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Library Events csv', type: :request do
  ['/library-databases', '/library-databases.csv'].each do |path|
    describe "GET #{path}" do
      it 'returns a csv' do
        stub_libapps_token
        stub_libguides_az_list

        get path

        expect(response).to be_successful
        expect(response.media_type).to eq 'text/csv'
        expect(response.body).to include 'Digitized Iranian newspapers and periodicals held by the University of Manchester'
        expect { CSV.parse(response.body) }.not_to raise_error
      end
    end
  end
end
