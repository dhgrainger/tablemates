# /p/:access_token — a guest's personal link. Remembers them on this device
# and moves on to the party, so the token doesn't linger in the address bar.
class GuestSessionsController < ApplicationController
  include GuestAccess

  allow_unauthenticated_access
  rate_limit to: 30, within: 3.minutes, with: -> { head :too_many_requests }

  def show
    invitation = Invitation.find_by!(access_token: params[:access_token])
    remember_invitation invitation
    redirect_to party_path(invitation.event_id)
  end
end
