# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Absolute ID Generation' do
  context 'when not logged in' do
    it "doesn't display interactive elements" do
      visit '/absolute-ids'

      expect(page).not_to have_selector '#abid-form'
    end
  end

  context 'when logged in', js: true, in_browser: true do
    let(:user) { FactoryBot.create(:user) }

    it 'can create an absolute ID session' do
      sign_in user
      stub_aspace_login
      stub_locations
      stub_container_profiles
      stub_repositories
      stub_repository
      stub_resource_find_by_id(repository_id: 4, identifier: "ABID001", resource_id: "4188")
      stub_resource(resource_id: "4188", repository_id: 4)
      stub_tree_root(resource_id: "4188", repository_id: 4)
      stub_archival_object(archival_object_id: "1446368", repository_id: 4)

      visit '/absolute-ids'

      # Fill in barcode with a valid untaken barcode
      fill_in 'Barcode', with: '0000000000000'
      fill_in "Location", with: "East Asian Library (ea)"
      fill_in "Container Profile", with: "NBox (B)"
      fill_in "Repository", with: "University Archives"
      fill_in "Call Number", with: "ABID001"
      fill_in "Starting Box Number", with: "22"
      # Have to unfocus starting box number to enable ending box number.
      find("body").click
      fill_in "Ending Box Number", with: "24"
      expect(page).to have_content "Barcode is valid"
      click_button "Generate"
    end
  end
end
