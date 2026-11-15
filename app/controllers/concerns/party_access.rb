# For every controller that acts inside a party. Resolves the event and the
# viewer's own invitation, and 404s for anyone who isn't part of the party.
# Always load further records through @event, never by bare id.
module PartyAccess
  extend ActiveSupport::Concern
  include GuestAccess

  included do
    allow_unauthenticated_access
    before_action :set_party
    helper_method :current_invitation, :hosting?
  end

  private
    def set_party
      @event = Event.find_by(id: params[:party_id] || params[:id])
      @current_invitation = invitation_for(@event) if @event
      raise ActiveRecord::RecordNotFound unless @current_invitation
    end

    def current_invitation
      @current_invitation
    end

    def hosting?
      current_invitation.host?
    end

    def require_host
      raise ActiveRecord::RecordNotFound unless hosting?
    end

    def require_planning
      redirect_to party_path(@event), alert: "This party has been closed out." unless @event.planning?
    end
end
