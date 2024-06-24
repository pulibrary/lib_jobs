# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AirTableStaff::StaffDirectoryPerson do
  describe '#to_a' do
    it 'uses the order from the mapping' do
      json = {
        'pul:Preferred Name': 'Sage Archivist',
        'University ID': '987654321',
        'netid': 'ab1234',
        'University Phone': '(609) 555-1234',
        'Last Name': 'Archivist',
        'First Name': 'Phoenix',
        'Email': 'test@princeton.edu',
        'Address': '123 Lewis Library',
        'pul:Building': 'Stokes Library',
        'Division': 'ReCAP',
        'pul:Department': 'Cataloging and Metadata Services',
        'pul:Unit': 'Rare Books Cataloging Team',
        'pul:Team': 'IT, Discovery and Access Services',
        'Title': 'Library Software Engineer',
        'Area of Study': ['Chemistry', 'African American Studies']
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
        'Chemistry//African American Studies' # areasOfStudy
      ]

      expect(described_class.new(json).to_a).to eq(expected)
    end
  end
end
