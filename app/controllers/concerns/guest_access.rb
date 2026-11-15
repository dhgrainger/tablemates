# Guests have no account. The access tokens for the parties they've joined on
# this device live in a signed, permanent, http-only cookie, keyed by event id.
module GuestAccess
  extend ActiveSupport::Concern

  MAX_REMEMBERED_PARTIES = 25

  private
    def guest_tokens
      tokens = cookies.signed[:guest_tokens]
      tokens.is_a?(Hash) ? tokens : {}
    end

    def remember_invitation(invitation)
      tokens = guest_tokens.except(invitation.event_id.to_s).to_a.last(MAX_REMEMBERED_PARTIES - 1).to_h
      tokens[invitation.event_id.to_s] = invitation.access_token
      cookies.signed.permanent[:guest_tokens] = { value: tokens, httponly: true, same_site: :lax }
    end

    # The viewer's own Invitation for this event: the host's (via their User
    # session) or a guest's (via an access token remembered on this device).
    def invitation_for(event)
      if authenticated? && Current.user.id == event.host_id
        event.host_invitation
      elsif (token = guest_tokens[event.id.to_s]).present?
        event.invitations.find_by(access_token: token)
      end
    end
end
