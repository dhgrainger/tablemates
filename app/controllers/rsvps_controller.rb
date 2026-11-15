# The viewer's own invitation: their reply, name and Venmo username.
class RsvpsController < ApplicationController
  include PartyAccess

  def edit
  end

  def update
    if current_invitation.update(rsvp_params)
      redirect_to party_path(@event), notice: "Saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def rsvp_params
      permitted = params.expect(invitation: [ :guest_name, :email, :venmo_username, :rsvp_status ])
      # Replies are frozen once the party is closed out; the host always attends.
      unless @event.planning? && !hosting? && Invitation::GUEST_REPLIES.include?(permitted[:rsvp_status])
        permitted.delete(:rsvp_status)
      end
      permitted
    end
end
