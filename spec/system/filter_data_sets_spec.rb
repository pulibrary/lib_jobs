# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Filter Data Sets", type: :system do
  before do
    driven_by(:rack_test)
  end

  it "enables me to filter data sets by category" do
    FactoryBot.create :data_set, category: '123'
    FactoryBot.create :data_set, category: 'abc'
    visit "/"

    expect(page.body).to include('<td>123</td>').once
    expect(page.body).to include('<td>abc</td>').once

    select "abc", from: "category"
    click_button "Filter"

    expect(page.body).not_to include('<td>123</td>')
    expect(page.body).to include('<td>abc</td>').once

    click_button "Clear Filters"

    expect(page.body).to include('<td>123</td>').once
    expect(page.body).to include('<td>abc</td>').once
  end
end
