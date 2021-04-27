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
      stub_repository(repository_id: 4)
      stub_resource_find_by_id(repository_id: 4, identifier: 'ABID001', resource_id: '4188')
      stub_resource(resource_id: '4188', repository_id: 4)
      # I suspect AbIDs don't actually need all this location info, and probably
      # just needs the location URI
      stub_location(location_id: "23641")
      stub_location(location_id: "23640")
      stub_top_containers(ead_id: "ABID001", repository_id: 4)
      # First Barcode
      stub_barcode_search(repository_id: 4, identifier: '00000000000000')
      stub_barcode_search(repository_id: 4, identifier: 'B-000001')

      stub_top_container(repository_id: 4, top_container_id: '118112')
      stub_batch_update_container_profile(uri: "/container_profiles/3", top_container_ids: "118112", repository_id: 4)
      stub_batch_update_location(uri: "/locations/23641", top_container_ids: "118112", repository_id: 4)
      # Second Barcode
      stub_barcode_search(repository_id: 4, identifier: '00000000000018')
      stub_barcode_search(repository_id: 4, identifier: 'B-000002')
      stub_top_container(repository_id: 4, top_container_id: '118113')
      stub_batch_update_container_profile(uri: "/container_profiles/3", top_container_ids: "118113", repository_id: 4)
      stub_batch_update_location(uri: "/locations/23641", top_container_ids: "118113", repository_id: 4)
      # Third Barcode
      stub_barcode_search(repository_id: 4, identifier: '00000000000026')
      stub_barcode_search(repository_id: 4, identifier: 'B-000003')
      stub_top_container(repository_id: 4, top_container_id: '118114')
      stub_batch_update_container_profile(uri: "/container_profiles/3", top_container_ids: "118114", repository_id: 4)
      stub_batch_update_location(uri: "/locations/23641", top_container_ids: "118114", repository_id: 4)

      visit '/absolute-ids'

      # Fill in barcode with a valid untaken barcode
      fill_in 'Barcode', with: '0000000000000'
      # Ensure barcode is filled in - JS had a bug where it blocked it.
      # The JS is appending another 0 to the end of this barcode, I don't know
      # why. See https://github.com/pulibrary/lib_jobs/issues/140
      expect(find_field('Barcode', disabled: true).value).to eq '00000000000000'
      fill_in 'Location', with: 'East Asian Library (ea)'
      fill_in 'Container Profile', with: 'NBox (B)'
      fill_in 'Repository', with: 'University Archives'
      fill_in 'Call Number', with: 'ABID001'
      fill_in 'Starting Box Number', with: '22'
      # Have to unfocus starting box number to enable ending box number.
      find('body').click
      fill_in 'Ending Box Number', with: '24'
      find('body').click
      expect(page).to have_content 'Barcode is valid'
      click_button 'Generate'

      expect(page).to have_content "Generating" # Increase wait time - processing takes ~ 18 seconds for this request.
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

      wait_for_download

      report = CSV.parse(download_content, headers: true)
      first_row = report.first.to_h
      expect(first_row["Box Number"]).to eq "22"
      expect(first_row["AbID"]).to eq "B-000001"
      expect(first_row["Barcode"]).to eq "00000000000000"
      expect(report.length).to eq 3
    end
  end
end
