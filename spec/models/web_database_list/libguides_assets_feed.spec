# frozen_string_literal: true
require 'rails_helper'

RSpec.describe WebDatabaseList::LibguidesAssetsFeed, type: :model do
  describe 'authorization_header' do
    it 'can construct a valid authorization header' do
      access_token = instance_double(AccessToken)
      expect(access_token).to receive(:fetch).and_return('MY_GREAT_ACCESS_TOKEN')
      feed = described_class.new(access_token:)
      expect(feed.authorization_header).to eq('Authorization: Bearer MY_GREAT_ACCESS_TOKEN')
    end
  end
end
