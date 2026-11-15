# A fixed payment one guest owes another, created when the host closes out
# the party. Status is manual: the payer says "I paid", the recipient "Got it".
class Settlement < ApplicationRecord
  belongs_to :event, touch: true
  belongs_to :from_invitation, class_name: "Invitation"
  belongs_to :to_invitation, class_name: "Invitation"

  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }

  scope :involving, ->(invitation) { where(from_invitation: invitation).or(where(to_invitation: invitation)) }

  alias_method :from, :from_invitation
  alias_method :to, :to_invitation

  def paid?
    paid_at.present?
  end

  def confirmed?
    confirmed_at.present?
  end

  # Venmo is the only way to pay, so without the recipient's username the
  # settlement is blocked until they add one.
  def payable?
    to_invitation.venmo_username.present?
  end

  def mark_paid!
    update!(paid_at: Time.current) unless paid?
  end

  def confirm!
    transaction do
      update!(confirmed_at: Time.current) unless confirmed?
      event.mark_settled_if_done!
    end
  end
end
