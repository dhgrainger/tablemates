require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "strangers see the welcome page" do
    get root_path
    assert_response :success
    assert_select "a[href=?]", new_registration_path
  end

  test "hosts see their dashboard" do
    sign_in_as users(:alex)
    get root_path
    assert_response :success
    assert_select "h1", /Alex/
  end
end
