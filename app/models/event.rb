class Event < ApplicationRecord
  belongs_to :host, class_name: "User"
  class NotAllowed < StandardError; end

  has_many :settlements, dependent: :destroy
  has_many :contributions, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_one_attached :cover_image

  has_secure_token :invite_token

  enum :status, %w[planning closed settled].index_by(&:itself), default: "planning"

  normalizes :title, :location, with: ->(value) { value.squish }

  validates :title, presence: true, length: { maximum: 80 }
  validates :starts_at, presence: true
  validates :location, length: { maximum: 200 }
  validates :description, length: { maximum: 2000 }
  validates :forgive_under_cents, numericality: { only_integer: true, in: 0..10_000, message: "must be between $0 and $100" }
  validates :cover_image, image_attachment: { max_size: 5.megabytes }

  after_create :invite_host

  # Everyone looking at the party page gets a Turbo page refresh (morphed)
  # whenever the party changes. Invitations and contributions touch the event.
  broadcasts_refreshes

  scope :upcoming, -> { where(starts_at: Time.current.beginning_of_day..).order(:starts_at) }
  scope :past, -> { where(starts_at: ...Time.current.beginning_of_day).order(starts_at: :desc) }

  # The host takes part through an Invitation like everyone else, so all
  # split logic only ever deals with invitations.
  def host_invitation
    invitations.find_by!(user_id: host_id)
  end

  def attendees
    invitations.rsvp_yes.order(:id)
  end

  def shared_total_cents
    contributions.splittable.sum(:cost_cents)
  end

  # Freezes the live estimate into Settlement records.
  def close_out!
    with_lock do
      raise NotAllowed, "already closed out" unless planning?

      payments = SettleUp.for(self).payments
      payments.each do |payment|
        settlements.create!(from_invitation: payment.from, to_invitation: payment.to, amount_cents: payment.amount_cents)
      end
      update!(status: payments.empty? ? :settled : :closed)
    end
  end

  # The host can reopen until any settlement has been marked paid.
  def reopenable?
    !planning? && settlements.where.not(paid_at: nil).none?
  end

  def reopen!
    with_lock do
      raise NotAllowed, "a payment has already been made" unless reopenable?

      settlements.destroy_all
      update!(status: :planning)
    end
  end

  def mark_settled_if_done!
    update!(status: :settled) if closed? && settlements.where(confirmed_at: nil).none?
  end

  # Dollars-as-text accessor for forms.
  def forgive_under
    Money.decimal(forgive_under_cents)
  end

  def forgive_under=(dollars)
    self.forgive_under_cents = Money.parse_cents(dollars) || -1
  end

  private
    def invite_host
      invitations.create!(user: host, guest_name: host.name, email: host.email_address,
        venmo_username: host.venmo_username, rsvp_status: :yes)
    end
end
