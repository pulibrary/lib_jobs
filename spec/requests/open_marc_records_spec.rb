# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Open Marc Records', type: :request do
  it 'displays a record for download' do
    get '/open-marc-records'
    expect(response.body).to include('test.tar.gz')
  end
  it 'downloads a file' do
    get '/open-marc-records/download/0'
    expect(response.headers['Content-Type']).to eq 'application/gzip'
    expect(response.headers['Content-Disposition']).to eq "attachment; filename=\"test.tar.gz\"; filename*=UTF-8''test.tar.gz"
  end

  it 'raises an error for non-existant file' do
    expect do
      get '/open-marc-records/download/5'
    end.to raise_error(ActiveStorage::FileNotFoundError)
  end
end