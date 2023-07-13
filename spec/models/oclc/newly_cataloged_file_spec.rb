# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Oclc::NewlyCatalogedFile, type: :model do
  subject(:newly_cataloged_file) { described_class.new(data:) }
  let(:data) { Rails.root.join('spec', 'fixtures', 'oclc', 'metacoll.PUL.new.D20230706.T213019.MZallDLC.1.mrc').read }
  let(:freeze_time) { Time.utc(2023, 7, 12) }
  let(:new_csv_path_1) { Rails.root.join('spec', 'fixtures', 'oclc', '2023-07-12-newly-cataloged-by-lc-bordelon.csv') }
  let(:new_csv_path_2) { Rails.root.join('spec', 'fixtures', 'oclc', '2023-07-12-newly-cataloged-by-lc-darrington.csv') }

  around do |example|
    Timecop.freeze(freeze_time) do
      example.run
    end
  end

  after do
    File.delete(new_csv_path_1) if File.exist?(new_csv_path_1)
    File.delete(new_csv_path_2) if File.exist?(new_csv_path_2)
  end

  it 'can run a test' do
    newly_cataloged_file.process
  end

  it 'is configured' do
    expect(newly_cataloged_file.selectors.map { |selector| selector.keys.first.to_s }).to match_array(['bordelon', 'darrington'])
    expect(newly_cataloged_file.csv_file_path).to eq('spec/fixtures/oclc/')
  end

  context 'without an existing csv file' do
    it 'without an existing csv file, it creates a csv file' do
      expect(File.exist?(new_csv_path_1)).to be false
      newly_cataloged_file.process
      expect(File.exist?(new_csv_path_1)).to be true
    end

    it 'with an existing csv file, it appends to an existing file' do
      expect(File.exist?(new_csv_path_1)).to be false
      newly_cataloged_file.process
      expect(File.exist?(new_csv_path_1)).to be true
      newly_cataloged_file.process
      csv_file = CSV.read(new_csv_path_1)
      # the below expectation will change as we build out the CSV
      expect(csv_file.length).to eq(1)
    end
  end
end
