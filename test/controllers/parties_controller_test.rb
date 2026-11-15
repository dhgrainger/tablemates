require "test_helper"

class PartiesControllerTest < ActionDispatch::IntegrationTest
  setup { @event = events(:dinner) }

  test "the host sees their party" do
    sign_in_as users(:alex)
    get party_path(@event)

    assert_response :success
    assert_select "h1", "Dinner at Alex's"
    assert_select "#guest_list li", 4
    assert_select "a[href=?]", edit_event_path(@event)
  end

  test "a stranger gets a 404" do
    get party_path(@event)
    assert_response :not_found
  end

  test "another host gets a 404" do
    sign_in_as users(:sam)
    get party_path(@event)
    assert_response :not_found
  end

  test "an unknown party is a 404" do
    sign_in_as users(:alex)
    get party_path(id: 0)
    assert_response :not_found
  end
end
