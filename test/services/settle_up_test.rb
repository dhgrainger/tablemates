require "test_helper"
require_relative "settle_up_test_helper"

class SettleUpTest < ActiveSupport::TestCase
  include SettleUpTestHelper

  test "even split: everyone pays the person who paid" do
    alex, bea, cal, dee = people("Alex", "Bea", "Cal", "Dee")
    payments = settle([ alex, bea, cal, dee ], [ paid(alex, 10_000) ])

    assert_equal [ "Bea -> Alex 2500", "Cal -> Alex 2500", "Dee -> Alex 2500" ], describe(payments)
  end

  test "uneven pennies: $100 between 3" do
    alex, bea, cal = people("Alex", "Bea", "Cal")
    payments = settle([ alex, bea, cal ], [ paid(alex, 10_000) ])

    assert_equal [ "Bea -> Alex 3333", "Cal -> Alex 3333" ], describe(payments)
  end

  test "one person paid everything" do
    alex, bea, cal, dee, eve = people("Alex", "Bea", "Cal", "Dee", "Eve")
    payments = settle([ alex, bea, cal, dee, eve ], [ paid(cal, 12_345) ])

    assert_equal 4, payments.size
    assert payments.all? { |payment| payment.to == cal }
    assert_equal 12_345 - 2469, payments.sum(&:amount_cents)
  end

  test "nobody owes anything" do
    alex, bea, cal = people("Alex", "Bea", "Cal")

    assert_empty settle([ alex, bea, cal ], [])
    assert_empty settle([ alex, bea, cal ], [ paid(alex, 2000), paid(bea, 2000), paid(cal, 2000) ])
  end

  test "gifts are excluded" do
    alex, bea = people("Alex", "Bea")
    payments = settle([ alex, bea ], [ paid(alex, 4000), paid(bea, 9000, shared: false) ])

    assert_equal [ "Bea -> Alex 2000" ], describe(payments)
  end

  test "a guest with a $0 contribution pays their share" do
    alex, bea, cal = people("Alex", "Bea", "Cal")
    payments = settle([ alex, bea, cal ], [ paid(alex, 3000), paid(bea, 3000), paid(cal, 0) ])

    assert_equal [ "Cal -> Alex 1000", "Cal -> Bea 1000" ], describe(payments)
  end

  test "exact-match pairing settles equal amounts first, saving a payment" do
    # Balances: Alex -50, Bea -30 | Cal +30, Dee +25, Eve +25
    alex, bea, cal, dee, eve = people("Alex", "Bea", "Cal", "Dee", "Eve")
    shares = [
      FairShares::Share.new(invitation: alex, paid_cents: 0, share_cents: 5000),
      FairShares::Share.new(invitation: bea, paid_cents: 0, share_cents: 3000),
      FairShares::Share.new(invitation: cal, paid_cents: 3000, share_cents: 0),
      FairShares::Share.new(invitation: dee, paid_cents: 2500, share_cents: 0),
      FairShares::Share.new(invitation: eve, paid_cents: 2500, share_cents: 0)
    ]
    payments = SettleUp.new(shares: shares).payments

    # Greedy alone would need four payments (Alex->Cal, Bea->Dee, Alex->Eve, Bea->Eve).
    assert_equal [ "Alex -> Dee 2500", "Alex -> Eve 2500", "Bea -> Cal 3000" ], describe(payments)
  end

  test "greedy pass: largest debtor pays largest creditor" do
    alex, bea, cal, dee = people("Alex", "Bea", "Cal", "Dee")
    # Total 120.00, share 30.00 each. Alex +50, Bea +10, Cal -30, Dee -30.
    payments = settle([ alex, bea, cal, dee ], [ paid(alex, 8000), paid(bea, 4000) ])

    assert_equal [ "Cal -> Alex 3000", "Dee -> Alex 2000", "Dee -> Bea 1000" ], describe(payments)
  end

  test "never more than n - 1 payments, and they settle everyone exactly" do
    random = Random.new(7)
    300.times do
      attendees = people(*Array.new(random.rand(1..10)) { |i| "P#{i}" })
      items = Array.new(random.rand(0..15)) { paid(attendees.sample(random: random), random.rand(0..40_000), shared: random.rand < 0.85) }
      shares = FairShares.new(attendees: attendees, contributions: items).shares
      payments = SettleUp.new(shares: shares).payments

      assert_operator payments.size, :<=, [ attendees.size - 1, 0 ].max
      assert payments.all? { |payment| payment.amount_cents.is_a?(Integer) && payment.amount_cents > 0 }
      assert payments.none? { |payment| payment.from == payment.to }
      assert balances_after(shares, payments).values.all?(&:zero?)
    end
  end

  test "rounding option: every payment is whole dollars and the host absorbs the difference" do
    alex, bea, cal = people("Alex", "Bea", "Cal")
    items = [ paid(alex, 10_000) ]

    payments = settle([ alex, bea, cal ], items, host: alex, round_to_whole_dollars: true)

    # 33.33 each becomes 33.00 each; Alex (the host) is 66 cents short.
    assert_equal [ "Bea -> Alex 3300", "Cal -> Alex 3300" ], describe(payments)
  end

  test "rounding option: guests paying each other are still made whole to the dollar" do
    alex, bea, cal, dee = people("Alex", "Bea", "Cal", "Dee")
    # Total 101.50 -> shares 25.38, 25.38, 25.37, 25.37. Bea paid it all.
    shares = FairShares.new(attendees: [ alex, bea, cal, dee ], contributions: [ paid(bea, 10_150) ]).shares
    payments = SettleUp.new(shares: shares, host: alex, round_to_whole_dollars: true).payments

    assert payments.all? { |payment| (payment.amount_cents % 100).zero? }
    assert_equal [ "Alex -> Bea 2600", "Cal -> Bea 2500", "Dee -> Bea 2500" ], describe(payments)

    # Bea is owed 76.12 and receives 76.00; Cal and Dee owe 25.37 and pay 25.00.
    # Alex, the host, owes 25.38 but pays 26.00 — soaking up everyone's cents.
    after = balances_after(shares, payments)
    assert_equal 0, after.values.sum
    assert_equal 62, after[alex]
  end

  test "rounding option holds for arbitrary parties" do
    random = Random.new(11)
    200.times do
      attendees = people(*Array.new(random.rand(2..8)) { |i| "P#{i}" })
      host = attendees.first
      items = Array.new(random.rand(1..10)) { paid(attendees.sample(random: random), random.rand(0..30_000)) }
      shares = FairShares.new(attendees: attendees, contributions: items).shares
      payments = SettleUp.new(shares: shares, host: host, round_to_whole_dollars: true).payments

      assert payments.all? { |payment| (payment.amount_cents % 100).zero? && payment.amount_cents > 0 }
      assert_operator payments.size, :<=, attendees.size - 1
      balances_after(shares, payments).each do |person, left_over|
        next if person == host
        assert_operator left_over.abs, :<=, 50, "#{person} should be within 50 cents of square"
      end
    end
  end

  test "rounding needs to know who the host is" do
    alex, bea = people("Alex", "Bea")
    shares = FairShares.new(attendees: [ alex, bea ], contributions: [ paid(alex, 999) ]).shares

    assert_raises(ArgumentError) { SettleUp.new(shares: shares, round_to_whole_dollars: true) }
  end

  test "forgive-small-debts option drops payments under the threshold" do
    alex, bea, cal = people("Alex", "Bea", "Cal")
    # Total 63.00, share 21.00. Alex +39, Bea -19.50, Cal -19.50... make one small:
    items = [ paid(alex, 4000), paid(bea, 2000), paid(cal, 300) ]

    assert_equal [ "Bea -> Alex 100", "Cal -> Alex 1800" ], describe(settle([ alex, bea, cal ], items))
    assert_equal [ "Cal -> Alex 1800" ], describe(settle([ alex, bea, cal ], items, forgive_under_cents: 200))
    assert_equal [ "Bea -> Alex 100", "Cal -> Alex 1800" ], describe(settle([ alex, bea, cal ], items, forgive_under_cents: 100))
    assert_empty settle([ alex, bea, cal ], items, forgive_under_cents: 5000)
  end

  test "rounding and forgiving together" do
    alex, bea, cal = people("Alex", "Bea", "Cal")
    items = [ paid(alex, 4000), paid(bea, 2000), paid(cal, 349) ]
    # Total 63.49 -> shares 21.17, 21.16, 21.16. Bea -1.16 -> -1.00, Cal -17.67 -> -18.00.
    payments = settle([ alex, bea, cal ], items, host: alex, round_to_whole_dollars: true, forgive_under_cents: 500)

    assert_equal [ "Cal -> Alex 1800" ], describe(payments)
  end

  test "works from an event's real records and options" do
    event = events(:dinner)
    assert_equal [ "Cal Cook -> Alex Host 3000" ],
      SettleUp.for(event).payments.map { |p| "#{p.from.guest_name} -> #{p.to.guest_name} #{p.amount_cents}" }

    event.update!(forgive_under_cents: 5000)
    assert_empty SettleUp.for(event).payments
  end
end
