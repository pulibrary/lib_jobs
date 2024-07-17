# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AirTableStaff::StaffDirectoryMapping do
  let(:directory_mapping) { described_class.new }
  it 'has the expected form for fields' do
    expect(directory_mapping.fields).to be_an_instance_of(Array)
    directory_mapping.fields.each do |field|
      expect(field.keys).to include(:airtable_field, :airtable_field_id, :our_field)
    end
  end
end
