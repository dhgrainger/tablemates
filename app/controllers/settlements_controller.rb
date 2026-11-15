# Manual payment status. Only the payer can say "I paid"; only the recipient
# can say "Got it".
class SettlementsController < ApplicationController
  include PartyAccess

  before_action :set_settlement

  def pay
    raise ActiveRecord::RecordNotFound unless @settlement.from_invitation_id == current_invitation.id

    if @settlement.payable?
      @settlement.mark_paid!
      redirect_to party_settle_up_path(@event), notice: "Marked as paid. #{@settlement.to.first_name} will confirm when it arrives."
    else
      redirect_to party_settle_up_path(@event), alert: "#{@settlement.to.first_name} needs to add a Venmo username first."
    end
  end

  def confirm
    raise ActiveRecord::RecordNotFound unless @settlement.to_invitation_id == current_invitation.id

    if @settlement.paid?
      @settlement.confirm!
      redirect_to party_settle_up_path(@event), notice: "Thanks — payment confirmed."
    else
      redirect_to party_settle_up_path(@event), alert: "#{@settlement.from.first_name} hasn't marked this as paid yet."
    end
  end

  private
    def set_settlement
      @settlement = @event.settlements.find(params[:id])
    end
end
