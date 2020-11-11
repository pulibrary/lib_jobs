# frozen_string_literal: true

class FinanceReportTinyTdsAdapter
  def initialize(dbhost:, dbport:, dbuser:, dbpass:)
    @client = TinyTds::Client.new username: dbuser, password: dbpass, host: dbhost, port: dbport
  end

  # @param query [string]
  # @return array of hashes where the column names are the keys
  def execute(query:)
    @client.execute(query).to_a
  end

  def execute_staff_query(employee_id:)
    query = "SELECT * FROM Staff Join Staff2Positions on Staff.idStaff = Staff2Positions.idStaff " \
            "join Positions on Staff2Positions.idPosition = Positions.idPosition " \
            "FULL OUTER join [Units extensions] on Positions.idUnit = [Units extensions].idUnit " \
            "join JobCodes on Positions.JobCode = JobCodes.JobCode " \
            "join [Work units] on Positions.idUnit = [Work units].idUnit " \
            "join Building on Positions.idBuilding = Building.ID_Building " \
            "where PUID = '#{employee_id}'"
    execute(query: query)
  end
end
