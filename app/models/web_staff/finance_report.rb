# frozen_string_literal: true

module WebStaff
  class FinanceReport
    attr_reader :finance_adapter

    def initialize(finance_adapter: WebStaff::FinanceReportTinyTdsAdapter.new(dbhost: Rails.configuration.staff_directory['finance_db_host'],
                                                                              dbport: Rails.configuration.staff_directory['finance_db_port'],
                                                                              dbuser: Rails.configuration.staff_directory['finance_db_user'],
                                                                              dbpass: Rails.configuration.staff_directory['finance_db_password']))
      @finance_adapter = finance_adapter
    end

    def report(employee_id:)
      results = finance_adapter.execute_staff_query(employee_id: employee_id)
      return default_data if results.blank?

      db_data = results.first

      reformat_data(db_data: db_data)
    end

    private

    def reformat_data(db_data:)
      data = db_data
      database_unused_keys.each { |key| data.delete(key) }
      data['DivSect'] = [db_data['Division'], db_data['Section'], db_data['Unit']].reject(&:blank?).join("  ")
      data['Name'] = "#{db_data['lName']}, #{db_data['fName']}"
      data['lastName'] = data.delete('lName')
      data['firstName'] = data.delete('fName')
      data['middleName'] = data.delete('mName')
      data['nickName'] = data.delete('nName')
      data['BackupFireWarden'] = data.delete('Back Up Fire Warden')
      data['FireWarden'] = data.delete('Fire Warden')
      data['FireWardenNotes'] = data.delete('Fire Warden Notes')
      data
    end

    def database_unused_keys
      ['Active', 'Alphabetical', 'idBuilding', 'idDepartment', 'idPosition', 'idPosition Notes', 'idStaff2Positions', 'idUnit', 'Business_Unit', 'CLS_Staff', 'Code_Position', 'CreationDate',
       'Departmental', 'DirectoryOnly', 'EmplClass', 'EndDate', 'FTE', 'ID_Building', 'Inactive', 'JobCode', 'LocationCode', 'Nbr_Home', 'Note', 'PS_Position_No', 'PULA', 'PayGrade',
       'PositionFTE', 'Posted', 'PostedComments', 'Rank', 'Sal Plan', 'SecondaryPosition', 'Supervisor of PULA Staff', 'Supervisor of Staff', 'Supervisor of Students', 'TerminationDate']
    end

    def default_data
      { 'idStaff' => nil, 'PUID' => nil, 'Email' => nil, 'StartDate' => nil, 'NetID' => nil, 'LibraryTitle' => nil, 'Office' => nil, 'Phone' => nil,
        'StaffSort' => nil, 'UnitSort' => nil, 'DeptSort' => nil, 'Title' => nil, 'LongTitle' => nil, 'Department' => nil, 'Division' => nil, 'Section' => nil,
        'Unit' => nil, 'Building' => nil, 'DivSect' => nil, "Name" => nil, 'lastName' => nil, 'firstName' => nil, 'middleName' => nil, 'nickName' => nil,
        'FireWarden' => false, 'BackupFireWarden' => false, 'FireWardenNotes' => nil }
    end
  end
end
