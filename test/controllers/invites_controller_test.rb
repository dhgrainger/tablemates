require "test_helper"

class InvitesControllerTest < ActionDispatch::IntegrationTest
  setup { @event = events(:dinner) }

  test "anyone with the link sees the invite and an RSVP form" do
    get invite_path(@event.invite_token)

    assert_response :success
    assert_select "h1", "Dinner at Alex's"
    assert_select "form[action=?]", invite_path(@event.invite_token)
  end

  test "the invite page does not list guests or leak any tokens" do
    get invite_path(@event.invite_token)

    assert_select "#guest_list", count: 0
    @event.invitations.each { |invitation| assert_no_match invitation.access_token, response.body }
  end

  test "an unknown invite token is a 404" do
    get invite_path("nope")
    assert_response :not_found
  end

  test "RSVPing creates an invitation, remembers the guest and lands on the party" do
    assert_difference -> { @event.invitations.count } => 1 do
      post invite_path(@event.invite_token), params: { invitation: {
        guest_name: "Fay Feast", email: "fay@example.com", venmo_username: "@fay-feast", rsvp_status: "maybe"
      } }
    end

    invitation = @event.invitations.order(:id).last
    assert_redirected_to guest_access_path(invitation.access_token)
    assert invitation.rsvp_maybe?
    assert_equal "fay-feast", invitation.venmo_username
    assert_nil invitation.user

    follow_redirect!
    assert_redirected_to party_path(@event)
    follow_redirect!
    assert_response :success
    assert_select "#your_rsvp", /Fay Feast/
  end

  test "an invalid RSVP re-renders the form" do
    assert_no_difference -> { Invitation.count } do
      post invite_path(@event.invite_token), params: { invitation: { guest_name: "", venmo_username: "x" } }
    end
    assert_response :unprocessable_entity
    assert_select "#form_errors"
  end

  test "a guest cannot choose their own token, event or user" do
    post invite_path(@event.invite_token), params: { invitation: {
      guest_name: "Fay", access_token: "chosen", event_id: events(:brunch).id, user_id: users(:alex).id, rsvp_status: "pending"
    } }

    invitation = Invitation.order(:id).last
    assert_equal @event, invitation.event
    assert_not_equal "chosen", invitation.access_token
    assert_nil invitation.user_id
    assert invitation.rsvp_yes?
  end

  test "a returning guest goes straight to the party" do
    visit_as_guest invitations(:bea)

    get invite_path(@event.invite_token)
    assert_redirected_to party_path(@event)
  end

  test "the host goes straight to the party" do
    sign_in_as users(:alex)
    get invite_path(@event.invite_token)
    assert_redirected_to party_path(@event)
  end

  test "RSVPs are closed once the party is closed out" do
    @event.update!(status: "closed")

    get invite_path(@event.invite_token)
    assert_select "form", count: 0

    assert_no_difference -> { Invitation.count } do
      post invite_path(@event.invite_token), params: { invitation: { guest_name: "Late Larry" } }
    end
    assert_redirected_to invite_path(@event.invite_token)
  end
end
