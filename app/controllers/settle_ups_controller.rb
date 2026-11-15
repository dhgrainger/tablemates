# The settle-up screen. While planning it's a live estimate; after close-out
# it shows the fixed settlements. Guests only ever see their own payments;
# the host sees them all.
class SettleUpsController < ApplicationController
  include PartyAccess

  def show
    @fair_shares = FairShares.for(@event)
    @lines = @event.planning? ? SettleUp.for(@event).payments : @event.settlements.includes(:from_invitation, :to_invitation).order(:id).to_a
    @my_lines = @lines.select { |line| line.from == current_invitation || line.to == current_invitation }
  end
end
