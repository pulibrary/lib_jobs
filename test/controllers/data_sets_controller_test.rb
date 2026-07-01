# frozen_string_literal: true
require 'test_helper'

class DataSetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @data_set = data_sets(:one)
  end

  test "should get index" do
    get '/'
    assert_response :success
  end

  test "should show data_set" do
    get data_set_url(@data_set)
    assert_response :success
  end
end
