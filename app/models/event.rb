class Event < ApplicationRecord
  belongs_to :host, class_name: "User"
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
