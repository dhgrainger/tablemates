# Normalises and validates a `venmo_username` attribute.
# Shared by User (hosts) and Invitation (guests).
module VenmoUsername
  extend ActiveSupport::Concern

  FORMAT = /\A[A-Za-z0-9_-]{5,30}\z/

  included do
    normalizes :venmo_username, with: ->(value) { value.strip.delete_prefix("@").strip.presence }

    validates :venmo_username,
      format: { with: FORMAT, message: "should be 5–30 letters, numbers, hyphens or underscores" },
      allow_nil: true
  end
end
