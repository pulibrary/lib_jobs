# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Barcode Management' do
  context 'when not logged in' do
    it "doesn't display interactive elements" do
      visit '/barcodes'

      expect(page).not_to have_selector '#abid-form'
    end
  end

  context 'when logged in', js: true do
    let(:user) { FactoryBot.create(:user) }

    it 'validates that filled in barcodes are not used by a previous AbID' do
      sign_in user
      stub_aspace_login
      stub_locations
      stub_container_profiles
      stub_repositories
      absolute_id = FactoryBot.create(:absolute_id)

      visit '/barcodes'

      expect(page).to have_selector '#abid-form'
      expect(page).to have_field 'Barcode'

      # Fill in barcode with a valid untaken barcode
      fill_in 'Barcode', with: '0000000000000'
      expect(page).to have_content "Barcode is valid"

      # TODO: There's a bug - reset doesn't let us fill in this field again.
      # click_button "Reset"
      visit '/barcodes'
      fill_in 'Barcode', with: absolute_id.value
      expect(page).not_to have_content "Barcode is valid"
      expect(page).to have_content "This barcode has already been used."
    end
  end
end
