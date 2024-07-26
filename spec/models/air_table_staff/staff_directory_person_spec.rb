# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AirTableStaff::StaffDirectoryPerson do
  describe '#to_a' do
    it 'uses the order from the mapping' do
      json = {
        'fldL7tm4jVvYksIwl': 'Sage Archivist',
        'fldbquJ6Hn2eq1V2h': '987654321',
        'fldgarsg3FzD8xpE4': 'ab1234',
        'fldqulY6ehd5aIbR1': '(609) 555-1234',
        'fldvENk2uiLDHmYSw': 'Archivist',
        'fldnKprqGraSvNTJK': 'Phoenix',
        'fldbnDHHhDNlc2Lx8': 'test@princeton.edu',
        'fldKZxmtofNbXW4qS': '123 Lewis Library',
        'fldz6yBenvTjdClXZ': 'Stokes Library',
        'fldxpCzkJmhEkVqZt': 'ReCAP',
        'fld9NYFQePrPxbJJW': 'Cataloging and Metadata Services',
        'fldusiuPpfSql6vSk': 'Rare Books Cataloging Team',
        'fldGzh0SHZqlFk3aU': 'IT, Discovery and Access Services',
        'fldw0mjDdB48HstnB': 'Library Software Engineer',
        'fldypTXdkQGpYgVDC': ['Discovery', 'Library Systems'],
        'fld4JloN0LxiFaTiw': "Kevin has worked at Princeton since 2011. He has a M.S. in Library and Information Science from the University of Illinois at Urbana-Champaign." \
          "\n\nKevin heads the Discovery and Access Services Team that supports the Library Catalog. \n",
        'fld0MfgMlZd364YTR': 'https://github.com/kevinreiss',
        'fldCCTbVNKKBFXxrp': ['Chemistry', 'African American Studies'],
        'fldULoOUDSpoEpdAP': 'https://example.com',
        'fldXw9janMHvhBWvO': ['Industrial Relations', 'James Madison Program']
      }
      expected = [
        '987654321', # puid
        'ab1234', # netid
        '(609) 555-1234', # phone
        'Sage Archivist', # name
        'Archivist', # lastName
        'Phoenix', # firstName
        'test@princeton.edu', # email
        '123 Lewis Library', # address
        'Stokes Library', # building
        'ReCAP', # department
        'Cataloging and Metadata Services', # division
        'Rare Books Cataloging Team', # unit
        'IT, Discovery and Access Services', # team
        'Library Software Engineer', # title
        'Chemistry//African American Studies', # areasOfStudy
        'https://github.com/kevinreiss', # websiteUrl
        "Kevin has worked at Princeton since 2011. "\
          "He has a M.S. in Library and Information Science "\
          "from the University of Illinois at Urbana-Champaign."\
          "\n\nKevin heads the Discovery and Access Services Team "\
          "that supports the Library Catalog. \n", # bios
        'Discovery//Library Systems', # expertise
        'https://example.com', # mySchedulerLink
        'Industrial Relations//James Madison Program' # otherEntities
      ]

      expect(described_class.new(json).to_a).to eq(expected)
    end
  end
end
