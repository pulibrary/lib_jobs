# frozen_string_literal: true
require 'rails_helper'

RSpec.describe OpenMarcRecord, type: :model do
  it 'open marc records has data_dumps' do
    expect(OpenMarcRecord.data_dumps).to be_instance_of(Array)
    expect(OpenMarcRecord.data_dumps).to match_array(['test.tar.gz'])
  end

  it 'validates requested data dumps' do
    expect(OpenMarcRecord.valid?('test.tar.gz')).to be true
    expect(OpenMarcRecord.valid?('not_a_test.tar.gz')).to be false
  end

  it 'does not allow url characters in filenames' do
    allow(Rails).to receive(:root).and_return(Pathname.new('/rails'))
    expect(OpenMarcRecord.file_path(0)).to eq Pathname.new('/rails/spec/fixtures/open_marc_records/test.tar.gz')
  end
end
