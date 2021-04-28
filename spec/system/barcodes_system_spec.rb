# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Barcode Management' do
  context 'when not logged in' do
    it "doesn't display interactive elements" do
      visit '/barcodes'

      expect(page).not_to have_selector '.absolute-ids-batch-form'
    end
  end

  context 'when logged in', js: true do
    let(:user) { FactoryBot.create(:user) }

    before do
      sign_in user
      stub_aspace_login
      stub_locations
      stub_container_profiles
      stub_repositories
    end

    let(:absolute_id) do
      FactoryBot.create(:absolute_id)
    end

    it 'validates that new barcodes are not yet persisted for AbIDs' do
      visit '/barcodes'

      expect(page).to have_selector '.absolute-ids-batch-form'
      expect(page).to have_field 'Barcode'
      expect(page).to have_content "Please enter a unique 13-digit barcode"

      # Fill in barcode with a valid untaken barcode
      fill_in 'Barcode', with: '3210110319105'
      expect(page).to have_content "Barcode is valid"
    end

    xit 'validates that filled in barcodes are not used by a previous AbID' do
      absolute_id
      visit '/barcodes'

      expect(page).to have_selector '.absolute-ids-batch-form'
      expect(page).to have_field 'Barcode'

      # Fill in barcode with a valid untaken barcode
      fill_in 'Barcode', with: '3210110319105'
      expect(page).to have_content "Barcode is valid"

      click_button "Reset"
      fill_in 'Barcode', with: absolute_id.value
      expect(page).not_to have_content "Barcode is valid"
      expect(page).to have_content "This barcode has already been used."
    end
  end
end
