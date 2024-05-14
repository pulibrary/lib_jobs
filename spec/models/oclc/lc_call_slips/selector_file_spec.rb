# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Oclc::LcCallSlips::SelectorFile, type: :model, lc_call_slips: true do
  subject(:newly_cataloged_file) { described_class.new(temp_file:) }
  let(:oclc_fixture_file_path) { Rails.root.join('spec', 'fixtures', 'oclc', 'metacoll.PUL.new.D20230718.T213016.MZallDLC.1.mrc') }
  let(:temp_file) { Tempfile.new(encoding: 'ascii-8bit') }
  let(:freeze_time) { Time.utc(2023, 7, 12) }
  let(:new_csv_path_1) { Rails.root.join('spec', 'fixtures', 'oclc', '2023-07-12-newly-cataloged-by-lc-bordelon.csv') }
  let(:new_csv_path_2) { Rails.root.join('spec', 'fixtures', 'oclc', '2023-07-12-newly-cataloged-by-lc-darrington.csv') }
  let(:new_csv_path_3) { Rails.root.join('spec', 'fixtures', 'oclc', '2023-07-12-newly-cataloged-by-lc-hatfield.csv') }
  let(:selector_config) { Rails.application.config.lc_call_slips.selectors.first }
  let(:selector_csv) { Oclc::LcCallSlips::SelectorCSV.new(selector_config:) }

  around do |example|
    csv_paths = [new_csv_path_1, new_csv_path_2, new_csv_path_3]
    csv_paths.each { |path| File.delete(path) if File.exist?(path) }
    temp_file.write(File.open(oclc_fixture_file_path).read)
    Timecop.freeze(freeze_time) do
      example.run
    end
    csv_paths.each { |path| File.delete(path) if File.exist?(path) }
  end

  it 'is configured' do
    expect(newly_cataloged_file.selectors_config.map { |selector| selector.keys.first.to_s }).to match_array(['bordelon', 'darrington'])
  end

  it 'it writes the expected data to the file' do
    selector_csv.create
    expect(File.exist?(new_csv_path_1)).to be true
    newly_cataloged_file.process
    csv_file = CSV.read(new_csv_path_1)
    expect(csv_file.length).to eq(14)

    first_row = csv_file[1]
    expect(first_row[0]).to eq('on1287917432')
    expect(first_row[1]).to eq('9789390569939')
    expect(first_row[2]).to eq('2020514908')
    expect(first_row[3]).to eq('Itty, John M.')
    expect(first_row[4]).to eq('Biblical perspective on political economy and empire')
    expect(first_row[5]).to eq('ii')
    expect(first_row[6]).to eq('Kashmere Gate, Delhi')
    expect(first_row[7]).to eq("ISPCK")
    expect(first_row[8]).to eq('2021')
    expect(first_row[9]).to eq('xxx, 229 pages ; 23 cm')
    expect(first_row[10]).to eq('am')
    expect(first_row[11]).to eq('eng')
    expect(first_row[12]).to eq('BR115.E3 I889 2021')
    expect(first_row[13]).to eq("Bible -- Criticism, interpretation, etc | " \
      "Christianity -- Economic aspects -- Biblical teaching | " \
      "Economics -- Religious aspects -- Christianity | Kingdom of God -- Biblical teaching")

    second_row = csv_file[2]
    expect(second_row[1]).to eq('9787221165381')
    expect(second_row[4]).to eq('Guizhou bao xian bai nian')
    expect(second_row[14]).to eq('贵州保险百年')
  end
end
