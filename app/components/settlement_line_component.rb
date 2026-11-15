# One payment, worded for whoever is looking at it. `line` is either a live
# SettleUp::Payment (an estimate) or a Settlement record (fixed, actionable).
class SettlementLineComponent < ViewComponent::Base
  def initialize(line:, viewer:, event:)
    @line = line
    @viewer = viewer
    @event = event
  end

  def settlement?
    @line.is_a?(Settlement)
  end

  def paying?
    @line.from == @viewer
  end

  def receiving?
    @line.to == @viewer
  end

  def amount
    Money.format(@line.amount_cents)
  end

  def headline
    if paying?
      "You owe #{@line.to.first_name} #{amount}"
    elsif receiving?
      "#{@line.from.first_name} owes you #{amount}"
    else
      "#{@line.from.guest_name} owes #{@line.to.guest_name} #{amount}"
    end
  end

  def status
    if !settlement? then [ "Estimate", "badge-ghost" ]
    elsif @line.confirmed? then [ "Settled", "badge-success" ]
    elsif @line.paid? then [ "Paid · awaiting confirmation", "badge-warning" ]
    elsif !@line.payable? then [ "Needs Venmo", "badge-error" ]
    else [ "Unpaid", "badge-ghost" ]
    end
  end

  def pay_url
    helpers.venmo_pay_url(username: @line.to.venmo_username, amount_cents: @line.amount_cents, note: helpers.venmo_note(@event))
  end
end
