# Host only: close out the party (fix the settlements) or reopen it.
class CloseOutsController < ApplicationController
  include PartyAccess

  before_action :require_host

  def create
    @event.close_out!
    redirect_to party_settle_up_path(@event), notice: @event.settled? ? "Closed out — nobody owes anything." : "Party closed out. Time to settle up!"
  rescue Event::NotAllowed
    redirect_to party_settle_up_path(@event), alert: "This party is already closed out."
  end

  def destroy
    @event.reopen!
    redirect_to party_path(@event), notice: "Party reopened. Costs can be edited again.", status: :see_other
  rescue Event::NotAllowed
    redirect_to party_settle_up_path(@event), alert: "A payment has already been made, so the party can't be reopened.", status: :see_other
  end
end
