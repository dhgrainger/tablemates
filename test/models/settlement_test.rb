require "test_helper"

class SettlementTest < ActiveSupport::TestCase
  setup do
    @event = events(:dinner)
    @alex = invitations(:alex_at_dinner)
    @cal = invitations(:cal)
  end

  test "closing out fixes the estimate into settlements" do
    @event.close_out!

    assert @event.closed?
    settlement = @event.settlements.sole
    assert_equal @cal, settlement.from
    assert_equal @alex, settlement.to
    assert_equal 3000, settlement.amount_cents
    assert_not settlement.paid?
  end

  test "closing out twice is not allowed" do
    @event.close_out!
    assert_raises(Event::NotAllowed) { @event.close_out! }
    assert_equal 1, @event.settlements.count
  end

  test "a party where nobody owes anything goes straight to settled" do
    event = events(:old_bbq)
    event.close_out!

    assert event.settled?
    assert_empty event.settlements
  end

  test "settlements stay fixed even if the numbers would now differ" do
    @event.close_out!
    contributions(:wine).update_columns(cost_cents: 99_900)

    assert_equal 3000, @event.settlements.sole.amount_cents
  end

  test "the host can reopen until a payment is marked paid" do
    @event.close_out!
    assert @event.reopenable?

    @event.reopen!
    assert @event.planning?
    assert_empty @event.settlements

    @event.close_out!
    @event.settlements.sole.mark_paid!
    assert_not @event.reopenable?
    assert_raises(Event::NotAllowed) { @event.reopen! }
    assert @event.reload.closed?
    assert_equal 1, @event.settlements.count
  end

  test "a planning party is not reopenable" do
    assert_not @event.reopenable?
  end

  test "paid then confirmed; the party is settled once every payment is confirmed" do
    @event.close_out!
    settlement = @event.settlements.sole

    settlement.mark_paid!
    assert settlement.paid?
    assert @event.reload.closed?

    settlement.confirm!
    assert settlement.confirmed?
    assert @event.reload.settled?
  end

  test "blocked until the person being paid has a Venmo username" do
    @event.close_out!
    settlement = @event.settlements.sole
    assert settlement.payable?

    @alex.update!(venmo_username: nil)
    assert_not settlement.reload.payable?
  end

  test "amounts must be positive integers" do
    assert_not Settlement.new(event: @event, from_invitation: @cal, to_invitation: @alex, amount_cents: 0).valid?
    assert_not Settlement.new(event: @event, from_invitation: @cal, to_invitation: @alex, amount_cents: 10.5).valid?
  end
end
