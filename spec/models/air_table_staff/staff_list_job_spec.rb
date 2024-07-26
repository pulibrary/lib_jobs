# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AirTableStaff::StaffListJob, type: :model do
  before do
    stub_airtable
  end

  context 'job is turned off' do
    before do
      allow(Flipflop).to receive(:air_table_staff_list?).and_return(true)
    end
    describe('CSV file generation') do
      let(:file_path) { Pathname.new(Rails.root.join('tmp', "airtable_staff.csv")) }
      let(:first_row) do
        [
          '123', 'ab123', '(123) 123-1234', 'Phillip Librarian', 'Librarian', 'Phillip', 'ab123@princeton.edu',
          '123 Stokes', 'Stokes', 'Special Collections', 'Special and Distinctive Collections', nil, nil, 'Library Collections Specialist V', 'Virtual Reality',
          nil, "Hello\nMy research interests\nare\n\nfantastic!", nil, 'https://example.com', 'Industrial Relations//James Madison Program'
        ]
      end

      around do |example|
        File.delete(file_path) if File.exist?(file_path)
        example.run
        File.delete(file_path) if File.exist?(file_path)
      end

      it 'creates a CSV file' do
        job = described_class.new(filename: file_path)
        job.run
        expect(File.exist?(file_path)).to be true
      end

      it 'the CSV file has a header row and a data row' do
        job = described_class.new(filename: file_path)
        job.run
        expect(CSV.read(file_path).length).to eq(2)
      end

      it 'the first row of data is correct' do
        job = described_class.new(filename: file_path)
        job.run
        expect(CSV.read(file_path).second).to eq(first_row)
      end

      context 'when run at a particular time' do
        let(:run_time) { Time.zone.local(2022, 3, 14, 15, 9, 26) }
        before do
          allow(Time).to receive(:now).and_return(run_time)
        end
        it 'records that time in the database' do
          job = described_class.new(filename: file_path)
          job.run
          expect(DataSet.order('created_at').last.report_time).to eq(run_time)
        end
      end

      context 'when the process has already been run in the past hour' do
        let(:original_data_set) do
          FactoryBot.create(:data_set,
                                                    category: 'AirTableStaffDirectory',
                                                    data_file: 'library_staff_20221109.csv')
        end
        before do
          original_data_set.save
          allow(File).to receive(:exist?).and_return true
          allow(File).to receive(:mtime).and_return 1.minute.ago
        end

        it 'returns the existing dataset' do
          job = described_class.new(filename: file_path)
          expect { job.run }.not_to change { DataSet.count }
        end
      end
    end
  end

  context 'job is turned off' do
    before do
      allow(Flipflop).to receive(:air_table_staff_list?).and_return(false)
    end
    it 'logs that it is turned off' do
      stafflist_job = described_class.new(filename: 'should_not_exist.csv')
      stafflist_job.run
      data_set = DataSet.last
      expect(data_set.data).to eq('Airtable-based staff list is typically scheduled for this time, but it is turned off.  Go to /features to turn it back on.')
    end
    it 'does not create a CSV file' do
      stafflist_job = described_class.new(filename: 'should_not_exist.csv')
      stafflist_job.run

      expect(File.exist?('should_not_exist.csv')).to be false
    end
  end
end
