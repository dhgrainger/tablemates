# One person at one party. Guests have no account: holding the access_token
# is what makes you this guest.
class Invitation < ApplicationRecord
  include VenmoUsername

  belongs_to :event, touch: true
  belongs_to :user, optional: true

  has_secure_token :access_token

  GUEST_REPLIES = %w[yes maybe no].freeze
  MAX_PER_EVENT = 150

  enum :rsvp_status, %w[pending yes no maybe].index_by(&:itself), prefix: :rsvp, default: "pending"

  normalizes :guest_name, with: ->(value) { value.squish }
  normalizes :email, with: ->(value) { value.strip.downcase.presence }

  validates :guest_name, presence: true, length: { maximum: 60 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, length: { maximum: 254 }, allow_nil: true
  validate :host_always_attends
  validate :party_not_full, on: :create

  def host?
    user_id.present? && user_id == event.host_id
  end

  def first_name
    guest_name.split.first
  end

  private
    def party_not_full
      errors.add(:base, "This party is full") if event && event.invitations.count >= MAX_PER_EVENT
    end

    def host_always_attends
      errors.add(:rsvp_status, "can't be changed for the host") if host? && !rsvp_yes?
    end
end
