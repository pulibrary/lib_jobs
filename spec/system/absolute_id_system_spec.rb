# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Absolute ID Generation' do
  context 'when not logged in' do
    it "doesn't display interactive elements" do
      visit '/absolute-ids'

      expect(page).not_to have_selector '#abid-form'
    end
  end

  context 'when logged in', js: true do
    let(:user) { FactoryBot.create(:user) }

    it 'can create an absolute ID session' do
      sign_in user
      stub_aspace_login
      stub_locations
      stub_container_profiles
      stub_repositories
      stub_repository
      stub_resource_find_by_id(repository_id: 4, identifier: 'ABID001', resource_id: '4188')
      stub_resource(resource_id: '4188', repository_id: 4)
      # I suspect AbIDs don't actually need all this location info, and probably
      # just needs the location URI
      stub_location(location_id: "23641")
      # The following things are stubbed because the code uses this to find box
      # 22-24. We should be able to improve this via an advanced top container
      # search against ASpace, this is likely to be too slow for large real
      # collections.
      stub_tree_root(resource_id: '4188', repository_id: 4)
      # Stub 25 archival objects
      (1_446_368..1_446_393).each do |archival_object_id|
        stub_archival_object(archival_object_id: archival_object_id.to_s, repository_id: 4)
        stub_tree_node(resource_id: '4188', repository_id: 4, archival_object_id: archival_object_id.to_s)
      end
      # Stub 24 top containers attached to archival objects.
      (118_091..118_115).each do |top_container_id|
        stub_top_container(repository_id: 4, top_container_id: top_container_id)
      end

      visit '/absolute-ids'

      # Fill in barcode with a valid untaken barcode
      fill_in 'Barcode', with: '0000000000000'
      fill_in 'Location', with: 'East Asian Library (ea)'
      fill_in 'Container Profile', with: 'NBox (B)'
      fill_in 'Repository', with: 'University Archives'
      fill_in 'Call Number', with: 'ABID001'
      fill_in 'Starting Box Number', with: '22'
      # Have to unfocus starting box number to enable ending box number.
      find('body').click
      fill_in 'Ending Box Number', with: '24'
      expect(page).to have_content 'Barcode is valid'
      click_button 'Generate'

      expect(page).to have_button "Generating", disabled: true # Increase wait time - processing takes ~ 18 seconds for this request.
      Capybara.using_wait_time 30 do
        expect(page).to have_button "Generate"
      end
      expect(page).to have_button "Synchronize"
      expect(page).to have_link "Download Report"

      # Synchronize!
      # Box 24.
      stub_request(:post, "https://aspace.test.org/staff/api/repositories/4/top_containers/118114")
        .to_return(status: 200, body: "", headers: {})
      # Box 23
      stub_request(:post, "https://aspace.test.org/staff/api/repositories/4/top_containers/118113")
        .to_return(status: 200, body: "", headers: {})
      # Box 22
      stub_request(:post, "https://aspace.test.org/staff/api/repositories/4/top_containers/118112")
        .to_return(status: 200, body: "", headers: {})
      click_button "Synchronize"
      Capybara.using_wait_time 30 do
        expect(page).to have_selector(".lux-tag-item.green span", text: "synchronized", count: 3)
      end

      # Ensure Export XML button works.
      # There's no user feature here - so this is just to get coverage.
      click_link "Export XML Data"
      expect(page.body).to include "/repositories/4/top_containers/118099"
      doc = Nokogiri::XML(page.body)
      expect(doc.errors).to be_blank

      # Reporting
      visit '/absolute-ids'

      click_link "Download Report"
      csv = CSV.new(page.text, headers: true)
      first_row = csv.first.to_h
      expect(first_row["Box Number"]).to eq "22"
      expect(first_row["abID"]).to eq "B-000001"
      expect(first_row["Barcode"]).to eq "00000000000000"
      expect(first_row.keys.length).to eq 3
    end
  end
end
