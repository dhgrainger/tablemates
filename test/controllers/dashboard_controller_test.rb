require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "strangers see the welcome page" do
    get root_path
    assert_response :success
    assert_select "a[href=?]", new_registration_path
  end

  test "hosts see only their own parties, split into upcoming and past" do
    sign_in_as users(:alex)
    get root_path

    assert_response :success
    assert_select "h1", /Alex/
    assert_select "#upcoming_parties a[href=?]", party_path(events(:dinner))
    assert_select "#past_parties a[href=?]", party_path(events(:old_bbq))
    assert_select "a[href=?]", party_path(events(:brunch)), count: 0
  end
end
