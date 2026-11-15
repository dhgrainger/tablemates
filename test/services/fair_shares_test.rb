require "test_helper"
require_relative "settle_up_test_helper"

class FairSharesTest < ActiveSupport::TestCase
  include SettleUpTestHelper

  def shares_for(attendees, items)
    FairShares.new(attendees: attendees, contributions: items)
  end

  def balances(fair_shares)
    fair_shares.shares.to_h { |share| [ share.invitation.name, share.balance_cents ] }
  end

  test "even split" do
    alex, bea, cal, dee = people("Alex", "Bea", "Cal", "Dee")
    fair = shares_for([ alex, bea, cal, dee ], [ paid(alex, 10_000) ])

    assert_equal 10_000, fair.total_cents
    assert_equal [ 2500 ] * 4, fair.shares.map(&:share_cents)
    assert_equal({ "Alex" => 7500, "Bea" => -2500, "Cal" => -2500, "Dee" => -2500 }, balances(fair))
  end

  test "uneven pennies: $100 between 3 loses nothing" do
    alex, bea, cal = people("Alex", "Bea", "Cal")
    fair = shares_for([ alex, bea, cal ], [ paid(alex, 10_000) ])

    assert_equal [ 3334, 3333, 3333 ], fair.shares.map(&:share_cents)
    assert_equal 10_000, fair.shares.sum(&:share_cents)
    assert_equal({ "Alex" => 6666, "Bea" => -3333, "Cal" => -3333 }, balances(fair))
  end

  test "the extra cents go to the first attendees by id, whatever order they arrive in" do
    alex, bea, cal = people("Alex", "Bea", "Cal")
    fair = shares_for([ cal, alex, bea ], [ paid(cal, 200) ])

    assert_equal({ "Alex" => 67, "Bea" => 67, "Cal" => 66 }, fair.shares.to_h { |s| [ s.invitation.name, s.share_cents ] })
  end

  test "balances always sum to exactly zero" do
    random = Random.new(42)
    200.times do
      attendees = people(*Array.new(random.rand(1..9)) { |i| "P#{i}" })
      items = Array.new(random.rand(0..12)) { paid(attendees.sample(random: random), random.rand(0..50_000), shared: random.rand < 0.8) }
      fair = shares_for(attendees, items)

      assert_equal 0, fair.shares.sum(&:balance_cents)
      assert_equal fair.total_cents, fair.shares.sum(&:share_cents)
      assert fair.shares.all? { |share| share.share_cents.is_a?(Integer) && share.paid_cents.is_a?(Integer) }
    end
  end

  test "gifts are excluded from the total and from what the giver paid" do
    alex, bea = people("Alex", "Bea")
    fair = shares_for([ alex, bea ], [ paid(alex, 4000), paid(bea, 2500, shared: false) ])

    assert_equal 4000, fair.total_cents
    assert_equal({ "Alex" => 2000, "Bea" => -2000 }, balances(fair))
    assert_equal 0, fair.share_for(bea).paid_cents
  end

  test "a guest who contributed nothing still owes their share" do
    alex, bea, cal = people("Alex", "Bea", "Cal")
    fair = shares_for([ alex, bea, cal ], [ paid(alex, 3000), paid(bea, 3000), paid(cal, 0) ])

    assert_equal({ "Alex" => 1000, "Bea" => 1000, "Cal" => -2000 }, balances(fair))
  end

  test "nothing spent means nobody owes anything" do
    alex, bea = people("Alex", "Bea")
    fair = shares_for([ alex, bea ], [ needed_item ])

    assert_equal 0, fair.total_cents
    assert_equal({ "Alex" => 0, "Bea" => 0 }, balances(fair))
  end

  test "unclaimed items are ignored" do
    alex, bea = people("Alex", "Bea")
    fair = shares_for([ alex, bea ], [ paid(alex, 1000), needed_item ])
    assert_equal 1000, fair.total_cents
  end

  test "someone who paid but isn't attending is reimbursed in full and has no share" do
    alex, bea, cal = people("Alex", "Bea", "Cal")
    fair = shares_for([ alex, bea ], [ paid(cal, 3000) ])

    assert_equal({ "Alex" => -1500, "Bea" => -1500, "Cal" => 3000 }, balances(fair))
    assert_equal 0, fair.share_for(cal).share_cents
  end

  test "with nobody attending there is nothing to split" do
    alex = people("Alex").first
    fair = shares_for([], [ paid(alex, 3000) ])

    assert_equal 0, fair.total_cents
    assert_equal 0, fair.shares.sum(&:balance_cents)
  end

  test "works from an event's real records" do
    fair = FairShares.for(events(:dinner))

    # Alex, Bea and Cal are going; Dee is a maybe. Flowers are a gift.
    assert_equal 9000, fair.total_cents
    assert_equal 3, fair.attendee_count
    assert_equal 3000, fair.share_for(invitations(:alex_at_dinner)).balance_cents
    assert_equal 0, fair.share_for(invitations(:bea)).balance_cents
    assert_equal(-3000, fair.share_for(invitations(:cal)).balance_cents)
    assert_nil fair.share_for(invitations(:dee))
  end
end
