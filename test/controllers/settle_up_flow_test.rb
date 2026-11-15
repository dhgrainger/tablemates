require "test_helper"

class SettleUpFlowTest < ActionDispatch::IntegrationTest
  setup do
    @event = events(:dinner)
    @alex = invitations(:alex_at_dinner) # host, owed $30
    @bea = invitations(:bea)             # square
    @cal = invitations(:cal)             # owes $30
  end

  def close_out!
    @event.close_out!
    @settlement = @event.settlements.sole
  end

  # --- estimate while planning --------------------------------------------

  test "while planning, guests see a live estimate of their own position" do
    visit_as_guest @cal
    get party_settle_up_path(@event)

    assert_response :success
    assert_select "#my_settlements", /You owe Alex \$30\.00/
    assert_select "#my_settlements", /Estimate/
    assert_select "a", text: "Pay on Venmo", count: 0
    assert_select "#why", /\$90\.00/
  end

  test "the party page shows each viewer their own estimate" do
    visit_as_guest @cal
    get party_path(@event)
    assert_select "#settle_up", /You owe Alex \$30\.00/
  end

  # --- close out -----------------------------------------------------------

  test "only the host can close out" do
    visit_as_guest @bea
    post party_close_out_path(@event)
    assert_response :not_found
    assert @event.reload.planning?

    sign_in_as users(:sam)
    post party_close_out_path(@event)
    assert_response :not_found

    sign_out
    post party_close_out_path(events(:brunch))
    assert_response :not_found
    assert @event.reload.planning?
  end

  test "the host closes out the party" do
    sign_in_as users(:alex)
    assert_difference -> { @event.settlements.count } => 1 do
      post party_close_out_path(@event)
    end

    assert_redirected_to party_settle_up_path(@event)
    assert @event.reload.closed?
  end

  test "the host reopens until someone has paid; guests can't" do
    close_out!

    visit_as_guest @cal
    delete party_close_out_path(@event)
    assert_response :not_found
    assert @event.reload.closed?

    sign_in_as users(:alex)
    delete party_close_out_path(@event)
    assert @event.reload.planning?
    assert_empty @event.settlements

    close_out!
    @settlement.mark_paid!
    delete party_close_out_path(@event)
    assert @event.reload.closed?
    assert_equal "A payment has already been made, so the party can't be reopened.", flash[:alert]
  end

  # --- what each person sees ----------------------------------------------

  test "the payer sees a Venmo button for exactly what they owe" do
    close_out!
    visit_as_guest @cal
    get party_settle_up_path(@event)

    assert_select "#my_settlements", /You owe Alex \$30\.00/
    assert_select "a[href^='https://account.venmo.com/pay?']", text: "Pay on Venmo" do |links|
      params = Rack::Utils.parse_query(URI.parse(links.first["href"]).query)
      assert_equal "alex-host", params["recipients"]
      assert_equal "30.00", params["amount"]
      assert_equal "pay", params["txn"]
      assert_match "Dinner at Alex's", params["note"]
    end
    assert_select "a[href=?]", "https://venmo.com/u/alex-host", text: "Check it's Alex"
    assert_select "form[action=?]", pay_party_settlement_path(@event, @settlement)
  end

  test "the recipient sees who owes them, with no pay button" do
    close_out!
    sign_in_as users(:alex)
    get party_settle_up_path(@event)

    assert_select "#my_settlements", /Cal owes you \$30\.00/
    assert_select "#my_settlements a", text: "Pay on Venmo", count: 0
    assert_select "#all_settlements", /Cal Cook → Alex Host/
  end

  test "a guest sees only their own settlements, never other people's" do
    close_out!
    visit_as_guest @bea
    get party_settle_up_path(@event)

    assert_select "#my_settlements", /all square/
    assert_select "#all_settlements", count: 0
    assert_no_match "Cal", response.body
    assert_no_match "owes", response.body
  end

  test "someone not in the split is told why" do
    close_out!
    visit_as_guest invitations(:dee)
    get party_settle_up_path(@event)
    assert_select "#why", /not part of it/
  end

  test "strangers and other parties' guests can't see the settle-up" do
    close_out!

    get party_settle_up_path(@event)
    assert_response :not_found

    visit_as_guest invitations(:eve)
    get party_settle_up_path(@event)
    assert_response :not_found
  end

  # --- paid / confirmed ----------------------------------------------------

  test "the payer marks it paid and the recipient confirms" do
    close_out!

    visit_as_guest @cal
    patch pay_party_settlement_path(@event, @settlement)
    assert_redirected_to party_settle_up_path(@event)
    assert @settlement.reload.paid?
    assert_not @settlement.confirmed?

    sign_in_as users(:alex)
    get party_settle_up_path(@event)
    assert_select "form[action=?]", confirm_party_settlement_path(@event, @settlement)

    patch confirm_party_settlement_path(@event, @settlement)
    assert @settlement.reload.confirmed?
    assert @event.reload.settled?
  end

  test "only the payer can mark a settlement paid" do
    close_out!

    visit_as_guest @bea
    patch pay_party_settlement_path(@event, @settlement)
    assert_response :not_found

    sign_in_as users(:alex) # the recipient (and host) can't either
    patch pay_party_settlement_path(@event, @settlement)
    assert_response :not_found

    assert_not @settlement.reload.paid?
  end

  test "only the recipient can confirm, and only after it's marked paid" do
    close_out!

    sign_in_as users(:alex)
    patch confirm_party_settlement_path(@event, @settlement)
    assert_not @settlement.reload.confirmed?

    @settlement.mark_paid!
    sign_out

    visit_as_guest @cal # the payer can't confirm their own payment
    patch confirm_party_settlement_path(@event, @settlement)
    assert_response :not_found

    visit_as_guest @bea
    patch confirm_party_settlement_path(@event, @settlement)
    assert_response :not_found

    assert_not @settlement.reload.confirmed?
  end

  test "a guest of another party can't touch this party's settlements" do
    close_out!
    visit_as_guest invitations(:eve)

    patch pay_party_settlement_path(@event, @settlement)
    assert_response :not_found
    patch pay_party_settlement_path(events(:brunch), @settlement)
    assert_response :not_found
    assert_not @settlement.reload.paid?
  end

  # --- no Venmo username ---------------------------------------------------

  test "a settlement is blocked until the creditor adds a Venmo username" do
    @alex.update!(venmo_username: nil)
    close_out!

    visit_as_guest @cal
    get party_settle_up_path(@event)
    assert_select "a", text: "Pay on Venmo", count: 0
    assert_select "##{dom_id(@settlement)}", /hasn't added a Venmo username/

    patch pay_party_settlement_path(@event, @settlement)
    assert_not @settlement.reload.paid?

    sign_in_as users(:alex)
    get party_settle_up_path(@event)
    assert_select "##{dom_id(@settlement)} a[href=?]", edit_party_rsvp_path(@event), text: "Add my Venmo username"

    patch party_rsvp_path(@event), params: { invitation: { venmo_username: "alex-host" } }
    sign_out

    visit_as_guest @cal
    get party_settle_up_path(@event)
    assert_select "a", text: "Pay on Venmo"
  end
end
