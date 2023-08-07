# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Oclc::DataSyncExceptionFile, type: :model do
  let(:temp_file) { Tempfile.new(encoding: 'ascii-8bit') }
  let(:exception_file) { described_class.new(temp_file:) }
  let(:freeze_time) { Time.utc(2023, 7, 13, 10, 30, 5) }
  let(:oclc_fixture_file_path) { 'spec/fixtures/oclc/PUL-PUL.1012676.IN.BIB.D20230712.T115732756.1012676.pul.non-pcc_27837389230006421_new.mrc_1.BibExceptionReport.txt' }
  let(:new_file_for_alma_path_1) { 'spec/fixtures/oclc/datasync_errors_20230713_103005_1.mrc' }
  let(:new_file_for_alma_path_2) { 'spec/fixtures/oclc/datasync_errors_20230713_103005_2.mrc' }
  it 'can be instantiated with a temp_file and new file for alma' do
    expect(described_class.new(temp_file:)).to be
    expect(exception_file.temp_file).to be_an_instance_of(Tempfile)
    expect(exception_file.max_records_per_file).to eq(7)
  end

  context 'with a fixture file' do
    let(:duplicated_error_text) { 'Invalid relationship - when 1st $2 in 1st 655 is equal to lcgft, then $z in 655 must not be present' }
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
      expect(exception_file.process).to be
      expect(File.exist?(new_file_for_alma_path_1)).to be true
      expect(File.exist?(new_file_for_alma_path_2)).to be true
      new_file = File.read(new_file_for_alma_path_1)
      expect(new_file).to include('99127605741006421').once
      expect(new_file).to include('Validation Error')
      expect(new_file).to include('SEVERE')
      expect(new_file).to include('Invalid code in 1st $2 in 1st 600.')
      expect(new_file).to include('20230713')
      expect(new_file).to include('1390150469')
      # errors that have invalid subfield...$0 are excluded
      expect(new_file).not_to include('Invalid subfield 1st $0')
      # mms with no errors are excluded
      expect(new_file).not_to include('99127132156106421')
      # Duplicate errors for a single record are deleted
      expect(new_file.scan(duplicated_error_text).size).to eq(3)
    end
  end
end
