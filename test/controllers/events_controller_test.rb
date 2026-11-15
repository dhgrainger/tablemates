require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup { @event = events(:dinner) }

  test "strangers are sent to sign in" do
    get new_event_path
    assert_redirected_to new_session_path

    post events_path, params: { event: { title: "Nope", starts_at: 1.day.from_now } }
    assert_redirected_to new_session_path

    get edit_event_path(@event)
    assert_redirected_to new_session_path

    patch event_path(@event), params: { event: { title: "Hacked" } }
    assert_redirected_to new_session_path

    assert_no_difference -> { Event.count } do
      delete event_path(@event)
    end
    assert_redirected_to new_session_path
  end

  test "a host creates a party" do
    sign_in_as users(:alex)

    get new_event_path
    assert_response :success

    assert_difference -> { users(:alex).hosted_events.count } => 1, -> { Invitation.count } => 1 do
      post events_path, params: { event: {
        title: "Taco night", starts_at: "2027-01-10T19:00", location: "My place", description: "Bring salsa",
        cover_image: fixture_file_upload("cover.png", "image/png")
      } }
    end

    event = Event.order(:id).last
    assert_redirected_to party_path(event)
    assert event.cover_image.attached?
    assert_equal users(:alex), event.host
  end

  test "invalid party re-renders the form" do
    sign_in_as users(:alex)
    post events_path, params: { event: { title: "", starts_at: "" } }
    assert_response :unprocessable_entity
    assert_select "#form_errors"
  end

  test "a non-image upload is rejected even when it claims to be an image" do
    sign_in_as users(:alex)

    assert_no_difference -> { Event.count } do
      post events_path, params: { event: {
        title: "Taco night", starts_at: "2027-01-10T19:00",
        cover_image: fixture_file_upload("not_an_image.txt", "image/png")
      } }
    end

    assert_response :unprocessable_entity
    assert_select "#form_errors", /must be a PNG/
  end

  test "a host cannot set the host, status or token" do
    sign_in_as users(:alex)
    post events_path, params: { event: {
      title: "Taco night", starts_at: "2027-01-10T19:00",
      host_id: users(:sam).id, status: "settled", invite_token: "chosen"
    } }

    event = Event.order(:id).last
    assert_equal users(:alex), event.host
    assert event.planning?
    assert_not_equal "chosen", event.invite_token
  end

  test "a host updates their party" do
    sign_in_as users(:alex)

    get edit_event_path(@event)
    assert_response :success

    patch event_path(@event), params: { event: { title: "Pasta night", round_to_whole_dollars: "1", forgive_under: "1.50" } }
    assert_redirected_to party_path(@event)

    @event.reload
    assert_equal "Pasta night", @event.title
    assert @event.round_to_whole_dollars?
    assert_equal 150, @event.forgive_under_cents
  end

  test "a host deletes their party" do
    sign_in_as users(:alex)
    assert_difference -> { Event.count } => -1 do
      delete event_path(@event)
    end
    assert_redirected_to root_path
  end

  test "another host cannot see, change or delete the party" do
    sign_in_as users(:sam)

    get edit_event_path(@event)
    assert_response :not_found

    patch event_path(@event), params: { event: { title: "Hacked" } }
    assert_response :not_found
    assert_equal "Dinner at Alex's", @event.reload.title

    assert_no_difference -> { Event.count } do
      delete event_path(@event)
    end
    assert_response :not_found
  end
end
