require "test_helper"

# Guests have no accounts: an access token (kept in a signed cookie) is all
# that identifies them. These tests pin down what that token does and doesn't
# let them reach.
class GuestAccessTest < ActionDispatch::IntegrationTest
  setup do
    @dinner = events(:dinner)
    @brunch = events(:brunch)
    @bea = invitations(:bea)
  end

  test "a personal link signs the guest in on this device" do
    get guest_access_path(@bea.access_token)
    assert_redirected_to party_path(@dinner)

    get party_path(@dinner)
    assert_response :success
    assert_select "#your_rsvp", /Bea Baker/
  end

  test "an unknown access token is a 404" do
    get guest_access_path("nope")
    assert_response :not_found
  end

  test "the token is kept in a signed cookie, not readable or forgeable in plain text" do
    visit_as_guest @bea
    assert_no_match @bea.access_token, cookies[:guest_tokens]

    cookies[:guest_tokens] = { @dinner.id.to_s => invitations(:cal).access_token }.to_json
    get party_path(@dinner)
    assert_response :not_found
  end

  test "a guest cannot see another event" do
    visit_as_guest @bea

    get party_path(@brunch)
    assert_response :not_found

    get edit_party_rsvp_path(@brunch)
    assert_response :not_found
  end

  test "a guest cannot modify another event" do
    visit_as_guest @bea

    patch party_rsvp_path(@brunch), params: { invitation: { guest_name: "Intruder", rsvp_status: "no" } }
    assert_response :not_found
    assert_equal "Eve Elsewhere", invitations(:eve).reload.guest_name
  end

  test "a guest cannot manage the party" do
    visit_as_guest @bea

    get edit_event_path(@dinner)
    assert_redirected_to new_session_path

    patch event_path(@dinner), params: { event: { title: "Hacked" } }
    assert_redirected_to new_session_path
    assert_equal "Dinner at Alex's", @dinner.reload.title
  end

  test "the party page never shows another guest's access token" do
    visit_as_guest @bea
    get party_path(@dinner)

    assert_match @bea.access_token, response.body
    @dinner.invitations.where.not(id: @bea.id).each do |other|
      assert_no_match other.access_token, response.body
    end
    assert_no_match @dinner.invite_token, response.body
  end

  test "the host sees the invite link but nobody's access token" do
    sign_in_as users(:alex)
    get party_path(@dinner)

    assert_match @dinner.invite_token, response.body
    @dinner.invitations.each { |invitation| assert_no_match invitation.access_token, response.body }
  end

  test "one device can be a guest at several parties" do
    visit_as_guest @bea
    visit_as_guest invitations(:eve)

    get party_path(@dinner)
    assert_select "#your_rsvp", /Bea Baker/
    get party_path(@brunch)
    assert_select "#your_rsvp", /Eve Elsewhere/
  end

  test "a signed-in host can also be a guest at someone else's party" do
    sign_in_as users(:alex)
    visit_as_guest invitations(:eve)

    get party_path(@brunch)
    assert_response :success
    assert_select "a[href=?]", edit_event_path(@brunch), count: 0
  end
end
