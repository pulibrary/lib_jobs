# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Filter and Sort Data Sets", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  it "enables me to filter data sets by category" do
    FactoryBot.create :data_set, category: '123'
    FactoryBot.create :data_set, category: 'abc'
    visit "/"

    expect(page).to have_selector 'td', text: '123', count: 1
    expect(page).to have_selector 'td', text: 'abc', count: 1

    select "abc", from: "category"
    click_button "Filter"

    expect(page).not_to have_selector 'td', text: '123'
    expect(page).to have_selector 'td', text: 'abc', count: 1

    click_button "Clear Filters"

    expect(page).to have_selector 'td', text: '123', count: 1
    expect(page).to have_selector 'td', text: 'abc', count: 1
  end

  describe "sorting" do
    let(:previous_time) { 3.days.ago.midnight }
    let(:today) { DateTime.now.midnight }
    let(:today_end_of_hour) { today.end_of_hour }

    let!(:data_set1) { create(:data_set, report_time: previous_time, data: "zzz999,yyy888", data_file: nil, category: "Oldest report") }
    let!(:data_set2) { create(:data_set, report_time: today, data: "abc123,def456", data_file: nil, category: "Middle report") }
    let!(:data_set3) { create(:data_set, report_time: today_end_of_hour, data: "abc123,def456", data_file: nil, category: "Newest report") }

    it "puts the newest report_time's first" do
      visit "/"
      rows = page.all('tbody tr')
      first_date = rows[0].find_css('td')[0].all_text
      first_category = rows[0].find_css('td')[1].all_text
      expect(first_category).to eq('Newest report')
      expect(first_date).to eq(data_set3.report_time.to_s)
      second_date = rows[1].find_css('td')[0].all_text
      second_category = rows[1].find_css('td')[1].all_text
      expect(second_category).to eq('Middle report')
      expect(second_date).to eq(data_set2.report_time.to_s)
      third_date = rows[2].find_css('td')[0].all_text
      third_category = rows[2].find_css('td')[1].all_text
      expect(third_category).to eq('Oldest report')
      expect(third_date).to eq(data_set1.report_time.to_s)
    end
  end
end
