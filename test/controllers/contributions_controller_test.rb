require "test_helper"

class ContributionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = events(:dinner)
    @bea = invitations(:bea)
    @cal = invitations(:cal)
    @wine = contributions(:wine)       # Bea's
    @salad = contributions(:salad)     # unclaimed
    @tiramisu = contributions(:tiramisu) # Cal's, no cost yet
  end

  # --- the board -----------------------------------------------------------

  test "the party page shows the board grouped by category with a shared total" do
    visit_as_guest @bea
    get party_path(@event)

    assert_select "#board h3", "Mains"
    assert_select "##{dom_id(@wine)}", /Two bottles of red/
    assert_select "##{dom_id(contributions(:flowers))} .badge", "Gift"
    assert_select "#shared_total", "$90.00"
    assert_select "turbo-cable-stream-source"
  end

  test "a guest sees edit only on their own items and claim only on unclaimed ones" do
    visit_as_guest @bea
    get party_path(@event)

    assert_select "a[href=?]", edit_party_contribution_path(@event, @wine)
    assert_select "a[href=?]", edit_party_contribution_path(@event, @tiramisu), count: 0
    assert_select "form[action=?]", claim_party_contribution_path(@event, @salad)
    assert_select "form[action=?]", claim_party_contribution_path(@event, @wine), count: 0
  end

  # --- adding --------------------------------------------------------------

  test "a guest adds their own item, which is theirs" do
    visit_as_guest @bea

    get new_party_contribution_path(@event)
    assert_response :success

    assert_difference -> { @event.contributions.count } => 1 do
      post party_contributions_path(@event), params: { contribution: { name: "Olives", category: "sides" } }
    end

    contribution = @event.contributions.order(:id).last
    assert_equal @bea, contribution.invitation
    assert contribution.sides?
    assert_redirected_to party_path(@event, anchor: "board")
  end

  test "a guest cannot add an item on someone else's behalf or to another party" do
    visit_as_guest @bea

    post party_contributions_path(@event), params: { contribution: {
      name: "Olives", invitation_id: @cal.id, event_id: events(:brunch).id, cost_cents: 99_999
    } }

    contribution = Contribution.order(:id).last
    assert_equal @bea, contribution.invitation
    assert_equal @event, contribution.event
    assert_equal 0, contribution.cost_cents
  end

  test "the host lists a needed item for guests to claim" do
    sign_in_as users(:alex)
    post party_contributions_path(@event), params: { contribution: { name: "Ice", category: "drinks", cost: "5" } }

    contribution = @event.contributions.order(:id).last
    assert_not contribution.claimed?
    assert_equal 0, contribution.cost_cents
  end

  test "the host can add something they are bringing themselves" do
    sign_in_as users(:alex)
    post party_contributions_path(@event), params: { contribution: { name: "Bread", mine: "1" } }
    assert_equal invitations(:alex_at_dinner), @event.contributions.order(:id).last.invitation
  end

  test "a guest cannot list an unclaimed item" do
    visit_as_guest @bea
    post party_contributions_path(@event), params: { contribution: { name: "Ice", mine: "0" } }
    assert_equal @bea, @event.contributions.order(:id).last.invitation
  end

  test "an invalid item re-renders the form" do
    visit_as_guest @bea
    post party_contributions_path(@event), params: { contribution: { name: "" } }
    assert_response :unprocessable_entity
  end

  # --- claiming ------------------------------------------------------------

  test "a guest claims an unclaimed item" do
    visit_as_guest @bea
    patch claim_party_contribution_path(@event, @salad)

    assert_equal @bea, @salad.reload.invitation
    assert_redirected_to party_path(@event, anchor: "board")
  end

  test "a guest cannot take an item someone else is bringing" do
    visit_as_guest @bea
    patch claim_party_contribution_path(@event, @tiramisu)

    assert_equal @cal, @tiramisu.reload.invitation
    assert_equal "Someone else is already bringing that.", flash[:alert]
  end

  test "a guest gives back their own item, but not someone else's" do
    visit_as_guest @cal
    patch unclaim_party_contribution_path(@event, @tiramisu)
    assert_nil @tiramisu.reload.invitation

    patch unclaim_party_contribution_path(@event, @wine)
    assert_response :not_found
    assert_equal @bea, @wine.reload.invitation
  end

  test "an item with a logged cost can't be handed back" do
    visit_as_guest @bea
    patch unclaim_party_contribution_path(@event, @wine)

    assert_equal @bea, @wine.reload.invitation
    assert_redirected_to edit_party_contribution_path(@event, @wine)
  end

  # --- editing, cost and receipts -----------------------------------------

  test "a guest logs the cost and a receipt for their own item" do
    visit_as_guest @cal

    get edit_party_contribution_path(@event, @tiramisu)
    assert_response :success

    patch party_contribution_path(@event, @tiramisu), params: { contribution: {
      cost: "18.75", receipt: fixture_file_upload("cover.png", "image/png")
    } }

    assert_redirected_to party_path(@event, anchor: "board")
    @tiramisu.reload
    assert_equal 1875, @tiramisu.cost_cents
    assert @tiramisu.receipt.attached?
  end

  test "a guest marks their item as a gift" do
    visit_as_guest @bea
    patch party_contribution_path(@event, @wine), params: { contribution: { gift: "1" } }
    assert_not @wine.reload.shared?
  end

  test "bad amounts and non-image receipts are rejected" do
    visit_as_guest @bea

    [ "-10", "abc", "100000.00", "1.999" ].each do |bad|
      patch party_contribution_path(@event, @wine), params: { contribution: { cost: bad } }
      assert_response :unprocessable_entity, "expected #{bad.inspect} to be rejected"
    end
    assert_equal 3000, @wine.reload.cost_cents

    patch party_contribution_path(@event, @wine), params: { contribution: {
      receipt: fixture_file_upload("not_an_image.txt", "image/png")
    } }
    assert_response :unprocessable_entity
    assert_not @wine.reload.receipt.attached?
  end

  test "a guest cannot edit another guest's contribution" do
    visit_as_guest @cal

    get edit_party_contribution_path(@event, @wine)
    assert_response :not_found

    patch party_contribution_path(@event, @wine), params: { contribution: { name: "Hacked", cost: "999" } }
    assert_response :not_found

    assert_no_difference -> { Contribution.count } do
      delete party_contribution_path(@event, @wine)
    end
    assert_response :not_found

    @wine.reload
    assert_equal "Two bottles of red", @wine.name
    assert_equal 3000, @wine.cost_cents
  end

  test "a guest cannot reassign their item to someone else or another party" do
    visit_as_guest @bea
    patch party_contribution_path(@event, @wine), params: { contribution: {
      name: "Still wine", invitation_id: @cal.id, event_id: events(:brunch).id, cost_cents: 1, shared: false
    } }

    @wine.reload
    assert_equal "Still wine", @wine.name
    assert_equal @bea, @wine.invitation
    assert_equal @event, @wine.event
    assert_equal 3000, @wine.cost_cents
    assert @wine.shared?
  end

  test "the host can edit and remove anyone's contribution" do
    sign_in_as users(:alex)

    patch party_contribution_path(@event, @wine), params: { contribution: { cost: "32.00" } }
    assert_equal 3200, @wine.reload.cost_cents

    assert_difference -> { Contribution.count } => -1 do
      delete party_contribution_path(@event, @tiramisu)
    end
  end

  test "a guest removes their own item" do
    visit_as_guest @cal
    assert_difference -> { Contribution.count } => -1 do
      delete party_contribution_path(@event, @tiramisu)
    end
  end

  test "removing a receipt" do
    @wine.receipt.attach(io: file_fixture("cover.png").open, filename: "receipt.png")
    visit_as_guest @bea

    patch party_contribution_path(@event, @wine), params: { contribution: { remove_receipt: "1" } }
    assert_not @wine.reload.receipt.attached?
  end

  # --- isolation between parties and from strangers ------------------------

  test "strangers can't touch the board" do
    get new_party_contribution_path(@event)
    assert_response :not_found

    assert_no_difference -> { Contribution.count } do
      post party_contributions_path(@event), params: { contribution: { name: "Nope" } }
      delete party_contribution_path(@event, @wine)
    end
    assert_response :not_found

    patch claim_party_contribution_path(@event, @salad)
    assert_response :not_found
    assert_nil @salad.reload.invitation
  end

  test "a guest of another party can't see or change this party's board" do
    visit_as_guest invitations(:eve)

    get edit_party_contribution_path(@event, @wine)
    assert_response :not_found

    patch party_contribution_path(@event, @wine), params: { contribution: { name: "Hacked" } }
    assert_response :not_found

    patch claim_party_contribution_path(@event, @salad)
    assert_response :not_found

    post party_contributions_path(@event), params: { contribution: { name: "Nope" } }
    assert_response :not_found
  end

  test "a guest can't reach another party's contribution through their own party's URL" do
    visit_as_guest @bea
    bagels = contributions(:bagels)

    get edit_party_contribution_path(@event, bagels)
    assert_response :not_found

    patch party_contribution_path(@event, bagels), params: { contribution: { name: "Hacked" } }
    assert_response :not_found

    patch claim_party_contribution_path(@event, bagels)
    assert_response :not_found
    assert_equal "Bagels", bagels.reload.name
    assert_equal invitations(:eve), bagels.invitation
  end

  test "another host can't change this party's board" do
    sign_in_as users(:sam)
    patch party_contribution_path(@event, @wine), params: { contribution: { name: "Hacked" } }
    assert_response :not_found
  end

  test "the board is frozen once the party is closed out" do
    @event.update!(status: "closed")
    visit_as_guest @bea

    patch party_contribution_path(@event, @wine), params: { contribution: { cost: "99" } }
    assert_redirected_to party_path(@event)
    assert_equal 3000, @wine.reload.cost_cents

    patch claim_party_contribution_path(@event, @salad)
    assert_nil @salad.reload.invitation

    assert_no_difference -> { Contribution.count } do
      post party_contributions_path(@event), params: { contribution: { name: "Late" } }
      delete party_contribution_path(@event, @wine)
    end
  end
end
