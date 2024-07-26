# frozen_string_literal: true
module AirTableStaff
  # This class is responsible for describing the fields in the
  # airtable and the resultant CSV, and how they are related
  class StaffDirectoryMapping
    # A mapping of:
    #  - an airtable field (airtable_field)
    #  - an airtable field id (airtable_field_id) - this should not change,
    #      even if the column name changes on airtable
    #  - a column name we want for our csv (our_field)
    #  - an optional "transformer" lambda for converting the airtable values
    #    to the desired format for the csv
    # rubocop:disable Metrics/MethodLength
    def fields
      [
        { airtable_field: :'University ID', airtable_field_id: :fldbquJ6Hn2eq1V2h, our_field: :puid },
        { airtable_field: :netid, airtable_field_id: :fldgarsg3FzD8xpE4, our_field: :netid },
        { airtable_field: :'University Phone', airtable_field_id: :fldqulY6ehd5aIbR1, our_field: :phone },
        { airtable_field: :'pul:Preferred Name', airtable_field_id: :fldL7tm4jVvYksIwl, our_field: :name },
        { airtable_field: :'pul:Last Name', airtable_field_id: :fldvENk2uiLDHmYSw, our_field: :lastName },
        { airtable_field: :'pul:First Name', airtable_field_id: :fldnKprqGraSvNTJK, our_field: :firstName },
        { airtable_field: :Email, airtable_field_id: :fldbnDHHhDNlc2Lx8, our_field: :email },
        { airtable_field: :Address, airtable_field_id: :fldKZxmtofNbXW4qS, our_field: :address },
        { airtable_field: :'pul:Building', airtable_field_id: :fldz6yBenvTjdClXZ, our_field: :building },
        { airtable_field: :Division, airtable_field_id: :fldxpCzkJmhEkVqZt, our_field: :department },
        { airtable_field: :'pul:Department', airtable_field_id: :fld9NYFQePrPxbJJW, our_field: :division },
        { airtable_field: :'pul:Unit', airtable_field_id: :fldusiuPpfSql6vSk, our_field: :unit },
        { airtable_field: :'pul:Team', airtable_field_id: :fldGzh0SHZqlFk3aU, our_field: :team },
        { airtable_field: :Title, airtable_field_id: :fldw0mjDdB48HstnB, our_field: :title },
        { airtable_field: :'Area of Study', airtable_field_id: :fldCCTbVNKKBFXxrp, our_field: :areasOfStudy, transformer: ->(areas) { areas&.join('//') } },
        { airtable_field: :'Website URL', airtable_field_id: :fld0MfgMlZd364YTR, our_field: :websiteUrl },
        { airtable_field: :Bios, airtable_field_id: :fld4JloN0LxiFaTiw, our_field: :bios },
        { airtable_field: :Expertise, airtable_field_id: :fldypTXdkQGpYgVDC, our_field: :expertise, transformer: ->(expertises) { expertises&.join('//') } },
        { airtable_field: :'My Scheduler Link', airtable_field_id: :fldULoOUDSpoEpdAP, our_field: :mySchedulerLink },
        { airtable_field: :'Other Entities', airtable_field_id: :fldXw9janMHvhBWvO, our_field: :otherEntities, transformer: ->(entities) { entities&.join('//') } }
      ]
    end
    # rubocop:enable Metrics/MethodLength

    def to_a
      @as_array ||= fields.pluck(:our_field)
    end
  end
end
