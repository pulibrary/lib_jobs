# frozen_string_literal: true
require 'rails_helper'

RSpec.describe WebStaff::StaffDirectoryDifference, type: :model do
  # these are actual lines in the file, so lets ignore rubocop an keep them together
  # rubocop:disable Layout/LineLength
  let(:report_header)  { '"PUID","NetID","Phone","Name","lastName","firstName","middleName","nickName","Title","LibraryTitle","LongTitle","Email","Section","Division","Department","StartDate","StaffSort","UnitSort","DeptSort","Unit","DivSect","FireWarden","BackupFireWarden","FireWardenNotes","Office","Building"' }

  let(:report_line1) { '"999999999","testi","732/111-2222","Test, Tester","Test","I","am","Tester","Library Office Assistant I","Library Office Assistant One","Library Office Assistant One","testi@princeton.edu",,,"Test Department Long",,,,,,,,0,,"B-1H-1","Firestone"' }
  let(:report_line2) { '"999999998","testii","732/111-2223","Test, Testi","Test","II","am","Testi","Library Office Assistant II","Library Office Assistant Two","Library Office Assistant Two","testii@princeton.edu",,,"Test Department Long",,,,,,,,0,,"223A","693 Alexander Road"' }
  let(:report_line3) { '"999999997","testiii","732/111-2224","Test, Testii","Test","III","am","Testii","Library Office Assistant III","Library Office Assistant Three","Library Office Assistant Three","testiii@princeton.edu",,,"Test Department Long",,,,,,,,0,,"Library Information Technology","Firestone Library"' }
  let(:report_line4) { '"999999996","testiv","732/111-2225","Test, Testiii","Test","III","am","Testiii","Library Office Assistant IV","Library Office Assistant Four","Library Office Assistant Four","testiv@princeton.edu",,,"Test Department Long",,,,,,,,0,,"Library Information Technology","Firestone Library"' }
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
