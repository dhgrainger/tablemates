require "application_system_test_case"

class PartyFlowTest < ApplicationSystemTestCase
  test "host creates a party, a guest RSVPs and contributes, and they settle up on Venmo" do
    # --- Host creates the party and lists what's needed ---
    sign_in_host users(:alex)
    click_link "New party"
    fill_in "What's the occasion?", with: "Taco Tuesday"
    fill_in "Where", with: "Alex's roof"
    click_button "Create party"

    assert_text "Party created"
    assert_selector "h1", text: "Taco Tuesday"
    invite_url = find("input[aria-label='Invite link']").value
    assert_match %r{/i/\w{24}}, invite_url

    click_link "Add an item"
    fill_in "What is it?", with: "Tortillas and fillings"
    select "Mains", from: "Category"
    check "I'm bringing this myself"
    click_button "Add to the board"
    click_link "Log cost"
    fill_in "What did it cost?", with: "60.00"
    click_button "Save"

    click_link "Add an item"
    fill_in "What is it?", with: "Limes"
    select "Sides", from: "Category"
    click_button "Add to the board"
    assert_text "Still needed"

    # --- A guest RSVPs with no account, claims an item and logs its cost ---
    using_session :guest do
      visit invite_url
      assert_text "Alex Host invited you"
      fill_in "Your name", with: "Gus Guest"
      fill_in "Venmo username", with: "@gus-guest"
      click_button "Send RSVP"

      assert_selector "#your_rsvp", text: "Gus Guest"
      assert_selector "#your_rsvp", text: "Venmo @gus-guest"

      click_button "I'll bring it"
      assert_text "It's yours"
      click_link "Log cost"
      fill_in "What did it cost?", with: "10"
      attach_file "Receipt photo", file_fixture("cover.png")
      click_button "Save"

      assert_selector "#shared_total", text: "$70.00"
      assert_selector "#settle_up", text: "You owe Alex $25.00"
    end

    # --- Host closes out ---
    visit current_path
    assert_selector "#shared_total", text: "$70.00"
    click_link "Review and close out"
    assert_text "Gus Guest → Alex Host $25.00"
    accept_confirm { click_button "Close out party" }
    assert_text "Party closed out"
    assert_text "Gus owes you $25.00"

    # --- Guest pays on Venmo and says so ---
    using_session :guest do
      visit current_path
      click_link "Settle up"
      assert_text "You owe Alex $25.00"

      pay_link = find_link("Pay on Venmo")[:href]
      assert_includes pay_link, "https://account.venmo.com/pay?"
      assert_includes pay_link, "amount=25.00"
      assert_includes pay_link, "recipients=alex-host"
      assert_link "Check it's Alex", href: "https://venmo.com/u/alex-host"

      find("summary", text: "Why?").click
      assert_text "Split between 2 people going"

      click_button "I paid"
      assert_text "Waiting for Alex to confirm"
    end

    # --- Host confirms; the party is settled ---
    visit current_path
    click_button "Got it"
    assert_text "payment confirmed"
    assert_text "Settled"

    click_link "Back"
    assert_text "All settled"
    assert_no_link "Add an item"
  end

  test "a stranger can't open a party, and a guest can't open someone else's" do
    visit party_path(events(:dinner))
    assert_no_text "Dinner at Alex's"

    visit guest_access_path(invitations(:eve).access_token)
    assert_selector "h1", text: "Sam's Brunch"

    visit party_path(events(:dinner))
    assert_no_text "Dinner at Alex's"
  end

  test "the invite link copies to the clipboard button and shows the right link" do
    sign_in_host users(:alex)
    visit party_path(events(:dinner))

    assert_equal invite_url(events(:dinner).invite_token), find("input[aria-label='Invite link']").value
    assert_button "Copy invite link"
  end
end
