require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  test "generates an unguessable access token" do
    invitation = events(:dinner).invitations.create!(guest_name: "Fay")
    assert_operator invitation.access_token.length, :>=, 24
    assert invitation.rsvp_pending?
  end

  test "requires a name; email is optional but must look like one" do
    event = events(:dinner)
    assert_not event.invitations.new(guest_name: " ").valid?
    assert event.invitations.new(guest_name: "Fay").valid?
    assert event.invitations.new(guest_name: "Fay", email: "fay@example.com").valid?
    assert_not event.invitations.new(guest_name: "Fay", email: "fay").valid?
  end

  test "normalises and validates the venmo username" do
    invitation = events(:dinner).invitations.new(guest_name: "Fay", venmo_username: " @fay-feasts ")
    assert_equal "fay-feasts", invitation.venmo_username
    assert invitation.valid?
    assert_not events(:dinner).invitations.new(guest_name: "Fay", venmo_username: "f a y").valid?
  end

  test "knows whether it is the host's" do
    assert invitations(:alex_at_dinner).host?
    assert_not invitations(:bea).host?
  end

  test "the host always attends" do
    assert_not invitations(:alex_at_dinner).update(rsvp_status: "no")
  end
end
