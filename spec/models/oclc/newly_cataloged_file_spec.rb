# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Oclc::NewlyCatalogedFile, type: :model do
  subject(:newly_cataloged_file) { described_class.new(temp_file:) }
  let(:oclc_fixture_file_path) { Rails.root.join('spec', 'fixtures', 'oclc', 'metacoll.PUL.new.D20230706.T213019.MZallDLC.1.mrc') }
  let(:temp_file) { Tempfile.new }
  let(:freeze_time) { Time.utc(2023, 7, 12) }
  let(:new_csv_path_1) { Rails.root.join('spec', 'fixtures', 'oclc', '2023-07-12-newly-cataloged-by-lc-bordelon.csv') }
  let(:new_csv_path_2) { Rails.root.join('spec', 'fixtures', 'oclc', '2023-07-12-newly-cataloged-by-lc-darrington.csv') }

  around do |example|
    File.delete(new_csv_path_1) if File.exist?(new_csv_path_1)
    File.delete(new_csv_path_2) if File.exist?(new_csv_path_2)
    temp_file.write(File.open(oclc_fixture_file_path).read)
    Timecop.freeze(freeze_time) do
      example.run
    end
    File.delete(new_csv_path_1) if File.exist?(new_csv_path_1)
    File.delete(new_csv_path_2) if File.exist?(new_csv_path_2)
  end

  it 'can run a test' do
    newly_cataloged_file.process
  end

  it 'is configured' do
    expect(newly_cataloged_file.selectors_config.map { |selector| selector.keys.first.to_s }).to match_array(['bordelon', 'darrington'])
    expect(newly_cataloged_file.csv_file_path).to eq('spec/fixtures/oclc/')
  end

  context 'without an existing csv file' do
    it 'without an existing csv file, it creates a csv file' do
      expect(File.exist?(new_csv_path_1)).to be false
      newly_cataloged_file.process
      expect(File.exist?(new_csv_path_1)).to be true
    end

    it 'it writes the expected data to the file' do
      expect(File.exist?(new_csv_path_1)).to be false
      newly_cataloged_file.process
      expect(File.exist?(new_csv_path_1)).to be true
      csv_file = CSV.read(new_csv_path_1)
      expect(csv_file.length).to eq(2)
      first_row = csv_file[1]
      expect(first_row[0]).to eq('on1389531111')
      expect(first_row[1]).to eq('')
      expect(first_row[2]).to eq('2023214610')
      expect(first_row[3]).to eq('')
      expect(first_row[4]).to eq('Oruzheĭnyĭ sbornik ')
      expect(first_row[5]).to eq('ru')
      expect(first_row[6]).to eq('Sankt-Peterburg ')
      expect(first_row[7]).to eq("Izdatel'stvo Gosudarstvennogo Ėrmitazha")
      expect(first_row[8]).to eq('2021-')
      expect(first_row[9]).to eq('volumes : illustrations ; 26 cm')
      expect(first_row[10]).to eq('as')
      expect(first_row[11]).to eq('rus | eng')
      expect(first_row[12]).to eq('U799 .O75')
      expect(first_row[13]).to eq((" Gosudarstvennyĭ Ėrmitazh (Russia) -- Congresses |" \
        "  Weapons -- History -- Congresses |  Armor -- History -- Congresses |" \
        "  Weapons -- Museums -- Russia (Federation) -- Congresses |" \
        "  Armor -- Museums -- Russia (Federation) -- Congresses"))
    end
  end
end
