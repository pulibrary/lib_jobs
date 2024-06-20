# frozen_string_literal: true
module AirTableStaff
  # This class is responsible for describing the fields in the
  # airtable and the resultant CSV, and how they are related
  class StaffDirectoryMapping
    # A mapping of:
    #  - an airtable field (airtable_field)
    #  - a column name we want for our csv (our_field)
    #  - an optional "transformer" lambda for converting the airtable values
    #    to the desired format for the csv
    # rubocop:disable Metrics/MethodLength
    def fields
      [
        { airtable_field: :'University ID', our_field: :puid },
        { airtable_field: :netid, our_field: :netid },
        { airtable_field: :'University Phone', our_field: :phone },
        { airtable_field: :'pul:Preferred Name', our_field: :name },
        { airtable_field: :'Last Name', our_field: :lastName },
        { airtable_field: :'First Name', our_field: :firstName },
        { airtable_field: :Email, our_field: :email },
        { airtable_field: :Address, our_field: :address },
        { airtable_field: :'pul:Building', our_field: :building },
        { airtable_field: :Division, our_field: :department },
        { airtable_field: :'pul:Department', our_field: :division },
        { airtable_field: :'pul:Unit', our_field: :unit },
        { airtable_field: :'pul:Team', our_field: :team },
        { airtable_field: :'Area of Study', our_field: :areasOfStudy, transformer: ->(areas) { areas&.join('//') } }
      ]
    end
    # rubocop:enable Metrics/MethodLength

    def to_a
      @as_array ||= fields.pluck(:our_field)
    end
  end
end
