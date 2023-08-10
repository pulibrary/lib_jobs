# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Oclc::BibProcessingFile, type: :model do
  let(:temp_file) { Tempfile.new(encoding: 'ascii-8bit') }
  let(:processing_file) { described_class.new(temp_file:) }
  let(:freeze_time) { Time.utc(2023, 7, 13, 10, 30, 5, 835_000) }
  let(:oclc_fixture_file_path) { 'spec/fixtures/oclc/PUL-PUL.1012676.IN.BIB.D20230712.T091935658.1012676.pul.non-pcc_28150407720006421_new.mrc_1.BibProcessingReport.txt' }
  let(:new_file_for_alma_path_1) { 'spec/fixtures/oclc/processing/xref_report_20230713_103005835_1.mrc' }
  let(:new_file_for_alma_path_2) { 'spec/fixtures/oclc/processing/xref_report_20230713_103005835_2.mrc' }
  it 'can be instantiated with a temp_file and new file for alma' do
    expect(described_class.new(temp_file:)).to be
    expect(processing_file.temp_file).to be_an_instance_of(Tempfile)
    expect(processing_file.max_records_per_file).to eq(7)
  end

  context 'with a fixture file' do
    around do |example|
      File.delete(new_file_for_alma_path_1) if File.exist?(new_file_for_alma_path_1)
      File.delete(new_file_for_alma_path_2) if File.exist?(new_file_for_alma_path_2)
      temp_file.write(File.open(oclc_fixture_file_path).read)
      Timecop.freeze(freeze_time) do
        example.run
      end
      File.delete(new_file_for_alma_path_1) if File.exist?(new_file_for_alma_path_1)
      File.delete(new_file_for_alma_path_2) if File.exist?(new_file_for_alma_path_2)
    end

    it 'creates a file to be submitted to alma' do
      expect(File.exist?(new_file_for_alma_path_1)).to be false
      expect(File.exist?(new_file_for_alma_path_2)).to be false
      expect(processing_file.process).to be
      expect(File.exist?(new_file_for_alma_path_1)).to be true
      expect(File.exist?(new_file_for_alma_path_2)).to be true
      new_file = File.read(new_file_for_alma_path_1)
      expect(new_file).to include('99127113255406421').once
      expect(new_file).to include('eunprocessed').exactly(7)
      expect(new_file).to include('20230713')
      # mms with errors are excluded
      expect(new_file).not_to include('99127603319606421')
    end
  end
end
