# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinanceReport, type: :model do
  let(:employee_id) { '999999999' }
  let(:db_results) do
    [{ 'idStaff' => 111, 'PUID' => '999999999', 'lName' => 'Smith', 'fName' => 'Jane', 'mName' => 'A', 'nName' => 'Janey', 'Email' => 'smith@princeton.edu', 'Active' => true,
       'StartDate' => Time.zone.parse('2019-04-15 00:00:00 -0400'), 'TerminationDate' => nil, 'NetID' => 'fouid', 'idStaff2Positions' => 4340, 'idPosition' => 626, 'EndDate' => nil,
       'Note' => 'job code changed from 3189 to 3389. Stan Yates was in this position with 3189 jobcode', 'FTE' => 1.0, 'Alphabetical' => true, 'Departmental' => true, 'SecondaryPosition' => false,
       'JobCode' => 3386, 'LibraryTitle' => 'The Great Assistant', 'PositionFTE' => 1.0, 'PayGrade' => '040', 'idUnit' => 133, 'Inactive' => false, 'idBuilding' => 19, 'Office' => 'B-18',
       'Rank' => 'AIT 040/ADMIN', 'Phone' => '111-222-333', 'Supervisor of Staff' => false, 'Supervisor of Students' => false, 'Supervisor of PULA Staff' => false, 'PS_Position_No' => 4887,
       'CLS_Staff' => 'ADMIN', 'Code_Position' => 99, 'Nbr_Home' => 690, 'idDepartment' => '41006', 'Business_Unit' => 'PUHRS', 'CreationDate' => Time.zone.parse('2003-07-02 00:00:00 -0400'),
       'StaffSort' => 10_000, 'PULA' => false, 'Posted' => false, 'PostedComments' => nil, 'Fire Warden' => false, 'Back Up Fire Warden' => false, 'Fire Warden Notes' => nil,
       'idPosition Notes' => nil, 'DirectoryOnly' => false, 'EmplClass' => 'Admin/HR Professional Staff', 'Sal Plan' => 'Information Tech Professional',
       'UnitSort' => 10_000, 'DeptSort' => 10, 'Title' => 'The Great Assistant', 'LongTitle' => 'The Great Assistant Is Longer', 'Department' => 'Lib-Research Coll & Presr',
       'Division' => 'Division from DB', 'Section' => 'section from DB', 'Unit' => nil, 'LocationCode' => nil, 'ID_Building' => 19, 'Building' => 'Firestone' }]
  end
  let(:finance_adapter) { instance_double(FinanceReportTinyTdsAdapter, execute_staff_query: db_results) }
  let(:generator) { described_class.new(finance_adapter: finance_adapter) }
  let(:report) do
    { 'idStaff' => 111, 'PUID' => '999999999', 'NetID' => 'fouid', 'Phone' => '111-222-333', "Name" => 'Smith, Jane', 'lastName' => 'Smith', 'firstName' => 'Jane', 'middleName' => 'A',
      'nickName' => 'Janey', 'Title' => 'The Great Assistant', 'LibraryTitle' => 'The Great Assistant', 'LongTitle' => 'The Great Assistant Is Longer', 'Email' => 'smith@princeton.edu',
      'Section' => 'section from DB', 'Division' => 'Division from DB', 'Department' => 'Lib-Research Coll & Presr', 'StartDate' => Time.zone.parse('2019-04-15 00:00:00 -0400'),
      'StaffSort' => 10_000, 'UnitSort' => 10_000, 'DeptSort' => 10, 'Unit' => nil, 'DivSect' => 'Division from DB  section from DB', 'FireWarden' => false, 'BackupFireWarden' => false,
      'FireWardenNotes' => nil, 'Office' => 'B-18', 'Building' => 'Firestone' }
  end

  it 'generates the staff list csv' do
    expect(generator.report(employee_id: employee_id)).to eq(report)
  end

  context "no adapter passes" do
    let(:generator) { described_class.new }

    it "uses the default adapter" do
      allow(FinanceReportTinyTdsAdapter).to receive(:new).with(dbhost: 'finance_db_host', dbport: 1433, dbuser: 'finance_db_user', dbpass: 'finance_db_password').and_return(finance_adapter)
      expect(generator.report(employee_id: employee_id)).to eq(report)
    end
  end

  context "a missing employee" do
    let(:finance_adapter) { instance_double(FinanceReportTinyTdsAdapter, execute_staff_query: []) }

    it "returns an empty hash" do
      expect(generator.report(employee_id: employee_id)).to eq({ "idStaff" => nil, "PUID" => nil, "NetID" => nil, "Phone" => nil, "Name" => nil, "lastName" => nil, "firstName" => nil,
                                                                 "middleName" => nil, "nickName" => nil, "Title" => nil, "LibraryTitle" => nil, "LongTitle" => nil, "Email" => nil,
                                                                 "Section" => nil, "Division" => nil, "Department" => nil, "StartDate" => nil, "StaffSort" => nil, "UnitSort" => nil,
                                                                 "DeptSort" => nil, "Unit" => nil, "DivSect" => nil, "FireWarden" => false, "BackupFireWarden" => false,
                                                                 "FireWardenNotes" => nil, "Office" => nil, "Building" => nil })
    end
  end
end
