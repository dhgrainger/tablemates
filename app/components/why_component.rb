# The expandable "Why?" under someone's settle-up: how their number was reached.
class WhyComponent < ViewComponent::Base
  def initialize(fair_shares:, viewer:, event:)
    @fair_shares = fair_shares
    @share = fair_shares.share_for(viewer)
    @event = event
  end

  def verdict
    balance = @share.balance_cents
    if balance.positive? then "You're owed #{helpers.money(balance)}"
    elsif balance.negative? then "You owe #{helpers.money(-balance)}"
    else "You're all square"
    end
  end
end
