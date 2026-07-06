# frozen_string_literal: true
require 'rails_helper'

RSpec.describe OpenMarcRecords::Repos::MarcFiles do
  describe '#list' do
    it 'lists files from the configured directory' do
      expect(described_class.new.list).to eq ['test.tar.gz']
    end
  end
  describe '#get_file_path' do
    it 'gives the full path to the requested file index' do
      allow(Hanami.app).to receive(:root).and_return(Pathname.new('/my-root'))
      expect(described_class.new.get_file_path(0)).to eq Some(Pathname.new('/my-root/spec/fixtures/open_marc_records/test.tar.gz'))
    end
  end
end
