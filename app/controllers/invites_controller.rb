# The public invite link. Anyone holding the invite token may see the party's
# details and RSVP; nothing else about the party is exposed here.
class InvitesController < ApplicationController
  include GuestAccess

  allow_unauthenticated_access
  rate_limit to: 20, within: 10.minutes, only: :create, with: -> { redirect_to invite_path(params[:invite_token]), alert: "Too many tries. Please wait a few minutes." }
  before_action :set_event
  before_action :redirect_existing_guest

  def show
    @invitation = @event.invitations.new(rsvp_status: :yes)
  end

  def create
    return redirect_to(invite_path(@event.invite_token), alert: "This party has wrapped up.") unless @event.planning?

    @invitation = @event.invitations.new(invitation_params)

    if @invitation.save
      remember_invitation @invitation
      redirect_to guest_access_path(@invitation.access_token)
    else
      render :show, status: :unprocessable_entity
    end
  end

  private
    def set_event
      @event = Event.find_by!(invite_token: params[:invite_token])
    end

    def redirect_existing_guest
      redirect_to party_path(@event) if invitation_for(@event)
    end

    def invitation_params
      params.expect(invitation: [ :guest_name, :email, :venmo_username, :rsvp_status ]).tap do |permitted|
        permitted[:rsvp_status] = "yes" unless Invitation::GUEST_REPLIES.include?(permitted[:rsvp_status])
      end
    end
end
