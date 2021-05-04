# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ArchivesSpace::ClearCacheJob do
  describe '#perform' do
    before do
      AbsoluteId::TopContainer.create
      AbsoluteId::Repository.create
      AbsoluteId::Resource.create
      AbsoluteId::ArchivalObject.create
    end

    it 'deletes all locally-cached ActiveRecord Models caching the ArchivalSpace resources' do
      expect(AbsoluteId::TopContainer.all.length).to eq(1)
      expect(AbsoluteId::Repository.all.length).to eq(1)
      expect(AbsoluteId::Resource.all.length).to eq(1)
      expect(AbsoluteId::ArchivalObject.all.length).to eq(1)

      described_class.perform_now

      expect(AbsoluteId::TopContainer.all).to be_empty
      expect(AbsoluteId::Repository.all).to be_empty
      expect(AbsoluteId::Resource.all).to be_empty
      expect(AbsoluteId::ArchivalObject.all).to be_empty
    end
  end
end
