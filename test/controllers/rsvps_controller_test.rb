require "test_helper"

class RsvpsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = events(:dinner)
    @bea = invitations(:bea)
  end

  test "strangers get a 404" do
    get edit_party_rsvp_path(@event)
    assert_response :not_found

    patch party_rsvp_path(@event), params: { invitation: { guest_name: "X" } }
    assert_response :not_found
  end

  test "a guest changes their own reply and details" do
    visit_as_guest @bea

    get edit_party_rsvp_path(@event)
    assert_response :success

    patch party_rsvp_path(@event), params: { invitation: { guest_name: "Bea B.", venmo_username: "@bea-new1", rsvp_status: "no" } }
    assert_redirected_to party_path(@event)

    @bea.reload
    assert_equal "Bea B.", @bea.guest_name
    assert_equal "bea-new1", @bea.venmo_username
    assert @bea.rsvp_no?
  end

  test "a guest can only ever change their own invitation" do
    visit_as_guest @bea

    patch party_rsvp_path(@event), params: { id: invitations(:cal).id, invitation: {
      id: invitations(:cal).id, guest_name: "Renamed", access_token: "chosen", user_id: users(:alex).id, event_id: events(:brunch).id
    } }

    assert_equal "Cal Cook", invitations(:cal).reload.guest_name
    @bea.reload
    assert_equal "Renamed", @bea.guest_name
    assert_equal "bea-dinner-access-token0", @bea.access_token
    assert_nil @bea.user_id
    assert_equal @event, @bea.event
  end

  test "invalid details re-render the form" do
    visit_as_guest @bea
    patch party_rsvp_path(@event), params: { invitation: { venmo_username: "no" } }
    assert_response :unprocessable_entity
  end

  test "the host can edit their details but always attends" do
    sign_in_as users(:alex)
    patch party_rsvp_path(@event), params: { invitation: { venmo_username: "alex-new1", rsvp_status: "no" } }

    host = invitations(:alex_at_dinner).reload
    assert_equal "alex-new1", host.venmo_username
    assert host.rsvp_yes?
  end

  test "after close-out a guest can still add Venmo but not change their reply" do
    @event.update!(status: "closed")
    cal = invitations(:cal)
    visit_as_guest cal

    patch party_rsvp_path(@event), params: { invitation: { venmo_username: "cal-cook", rsvp_status: "no" } }

    cal.reload
    assert_equal "cal-cook", cal.venmo_username
    assert cal.rsvp_yes?
  end
end
