# frozen_string_literal: true
require 'rails_helper'

RSpec.describe StaffDirectoryDifference, type: :model do
  # these are actual lines in the file, so lets ignore rubocop an keep them together
  # rubocop:disable Layout/LineLength
  let(:report_header)  { '"idStaff","PUID","NetID","Phone","Name","lastName","firstName","middleName","nickName","Title","LibraryTitle","LongTitle","Email","Section","Division","Department","StartDate","StaffSort","UnitSort","DeptSort","Unit","DivSect","FireWarden","BackupFireWarden","FireWardenNotes","Office","Building"' }

  let(:report_line1) { '111,"999999999","testi","111-222-333","Am, Tester","Am","Test","I","Tester","The Great Assistant","The Great Library Assistant","The Great Library Assistant","testi@princeton.edu","section from DB","Division from DB","Lib-Research Coll & Presr",04/15/2019 00:00:00,10000,1000,10,,"Division from DB  section from DB",0,0,,"B-18","Firestone"' }
  let(:report_line2) { '111,"999999998","testii","111-222-333","Am, Tester","Am","Test","II","Tester","The Great Assistant","The Great Library Assistant","The Great Library Assistant","testii@princeton.edu","section from DB","Division from DB","Lib-Research Coll & Presr",04/15/2019 00:00:00,10000,1000,10,,"Division from DB  section from DB",0,0,,"B-18","Firestone"' }
  let(:report_line3) { '111,"999999997","testiii","111-222-333","Am, Tester","Am","Test","III","Tester","The Great Assistant","The Great Library Assistant","The Great Library Assistant","testiii@princeton.edu","section from DB","Division from DB","Lib-Research Coll & Presr",04/15/2019 00:00:00,10000,1000,10,,"Division from DB  section from DB",0,0,,"B-18","Firestone"' }
  let(:report_line4) { '111,"999999997","testiiii","111-222-333","Am, Tester","Am","Test","IIII","Tester","The Great Assistant","The Great Library Assistant","The Great Library Assistant","testiiii@princeton.edu","section from DB","Division from DB","Lib-Research Coll & Presr",04/15/2019 00:00:00,10000,1000,10,,"Division from DB  section from DB",0,0,,"B-18","Firestone"' }
  # rubocop:enable Layout/LineLength

  let(:new_report) { "#{report_header}\n#{report_line1}\n#{report_line2}\n#{report_line4}\n" }
  let(:old_report) { "#{report_header}\n#{report_line2}\n#{report_line3}\n#{report_line1}\n" }

  let(:difference) { described_class.new(new_report: new_report, old_report: old_report) }

  it "differs the reports to tell who was deleted" do
    expect { expect(difference.ids).to eq(['testiii']) }.to change(DataSet, :count).by(2)
  end

  context "the difference was already run" do
    before do
      DataSet.create(report_time: DateTime.now.midnight, data: "abc123,def456", data_file: nil, category: "StaffDirectoryRemoved")
      DataSet.create(report_time: DateTime.now.midnight, data: "zzz999,yyy888", data_file: nil, category: "StaffDirectoryAdded")
    end

    it "reads the report from the datasets to tell who was deleted" do
      expect { expect(difference.ids).to eq(['abc123', 'def456']) }.to change(DataSet, :count).by(0)
    end
  end
end
