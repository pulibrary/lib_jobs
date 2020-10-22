require 'test_helper'

class DataSetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @data_set = data_sets(:one)
  end

  test "should get index" do
    get data_sets_url
    assert_response :success
  end

  test "should get new" do
    get new_data_set_url
    assert_response :success
  end

  test "should create data_set" do
    assert_difference('DataSet.count') do
      post data_sets_url, params: { data_set: {  } }
    end

    assert_redirected_to data_set_url(DataSet.last)
  end

  test "should show data_set" do
    get data_set_url(@data_set)
    assert_response :success
  end

  test "should get edit" do
    get edit_data_set_url(@data_set)
    assert_response :success
  end

  test "should update data_set" do
    patch data_set_url(@data_set), params: { data_set: {  } }
    assert_redirected_to data_set_url(@data_set)
  end

  test "should destroy data_set" do
    assert_difference('DataSet.count', -1) do
      delete data_set_url(@data_set)
    end

    assert_redirected_to data_sets_url
  end
end
