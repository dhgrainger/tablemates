require "test_helper"

class PaymentsHelperTest < ActionView::TestCase
  test "builds a pre-filled Venmo pay link" do
    url = venmo_pay_url(username: "alex-host", amount_cents: 2500, note: "🍝 Dinner at Alex's – Nov 22")
    uri = URI.parse(url)
    params = Rack::Utils.parse_query(uri.query)

    assert_equal "account.venmo.com", uri.host
    assert_equal "/pay", uri.path
    assert_equal({ "txn" => "pay", "recipients" => "alex-host", "amount" => "25.00", "note" => "🍝 Dinner at Alex's – Nov 22" }, params)
  end

  test "amounts are exact, with no float artefacts and no thousands separator" do
    amount = ->(cents) { Rack::Utils.parse_query(URI.parse(venmo_pay_url(username: "x", amount_cents: cents, note: "n")).query)["amount"] }

    assert_equal "0.05", amount.(5)
    assert_equal "33.33", amount.(3333)
    assert_equal "1234.56", amount.(123_456)
    assert_equal "0.29", amount.(29)
    assert_equal "1.10", amount.(110)
  end

  test "profile link" do
    assert_equal "https://venmo.com/u/alex-host", venmo_profile_url("alex-host")
  end

  test "note names the party and its date" do
    event = Event.new(title: "Dinner at Alex's", starts_at: Time.zone.local(2026, 11, 22, 19))
    assert_equal "🍝 Dinner at Alex's – Nov 22", venmo_note(event)
  end
end
