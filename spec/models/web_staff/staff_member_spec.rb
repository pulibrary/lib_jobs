# frozen_string_literal: true
require 'rails_helper'

RSpec.describe WebStaff::StaffMember, type: :model do
  let(:hr_person) do
    {
      'Title' => 'basic title',
      'Register Title' => 'more complete title',
      'E-Mail' => ''
    }
  end

  let(:staff_member) { described_class.new(hr_person) }

  before do
    allow(WebStaff::Ldap).to receive(:find_by_netid).and_return({})
  end

  it('uses a register title when it is available') do
    expect(staff_member.hash['LibraryTitle']).to eq('more complete title')
  end

  context 'register title is not available' do
    let(:hr_person) do
      {
        'Title' => 'basic title',
        'Register Title' => ' ',
        'E-Mail' => ''
      }
    end

    it('uses a the title field when the more descriptive register title field is unavailable') do
      expect(staff_member.hash['LibraryTitle']).to eq('basic title')
    end
  end

  context 'HR system returns a Princeton phone number' do
    let(:hr_person) do
      {
        'Title' => 'basic title',
        'Register Title' => ' ',
        'E-Mail' => '',
        'OL1 Phone - Phone Number' => '609/258-1234'
      }
    end

    it('includes Princeton phone number in the staff member hash') do
      expect(staff_member.hash['Phone']).to eq('(609) 258-1234')
    end
  end
  context 'HR system returns a personal phone number' do
    let(:hr_person) do
      {
        'Title' => 'basic title',
        'Register Title' => ' ',
        'E-Mail' => '',
        'OL1 Phone - Phone Number' => '555/123-4567'
      }
    end
    it('does not include personal phone number in the staff member hash') do
      expect(staff_member.hash['Phone']).to be_empty
    end
  end
end
