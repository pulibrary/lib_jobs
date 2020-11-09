# frozen_string_literal: true
require "application_system_test_case"

class DataSetsTest < ApplicationSystemTestCase
  setup do
    @data_set = data_sets(:one)
  end

  test "visiting the index" do
    visit data_sets_url
    assert_selector "h1", text: "Data Sets"
  end

  test "creating a Data set" do
    visit data_sets_url
    click_on "New Data Set"

    click_on "Create Data set"

    assert_text "Data set was successfully created"
    click_on "Back"
  end

  test "updating a Data set" do
    visit data_sets_url
    click_on "Edit", match: :first

    click_on "Update Data set"

    assert_text "Data set was successfully updated"
    click_on "Back"
  end

  test "destroying a Data set" do
    visit data_sets_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Data set was successfully destroyed"
  end
end
