# Something someone brings to the party. Unclaimed (no invitation) means the
# host listed it as needed and nobody has said "I'll bring it" yet.
class Contribution < ApplicationRecord
  CATEGORIES = {
    "mains" => "Mains", "sides" => "Sides", "drinks" => "Drinks",
    "dessert" => "Dessert", "other" => "Everything else"
  }.freeze

  belongs_to :event, touch: true
  belongs_to :invitation, optional: true
  has_one_attached :receipt

  enum :category, CATEGORIES.keys.index_by(&:itself), default: "other", validate: true

  normalizes :name, with: ->(value) { value.squish }

  validates :name, presence: true, length: { maximum: 80 }
  validates :cost_cents, numericality: { only_integer: true, in: 0..Money::MAX_CENTS, message: "must be between $0 and $10,000" }
  validates :receipt, image_attachment: { max_size: 10.megabytes }
  validate :cost_is_a_dollar_amount
  validate :claimed_by_a_guest_of_this_party
  validate :only_claimed_items_have_a_cost

  scope :splittable, -> { where(shared: true).where.not(invitation_id: nil) }

  def claimed?
    invitation_id.present?
  end

  def editable_by?(viewer)
    viewer.event_id == event_id && (viewer.host? || viewer.id == invitation_id)
  end

  # Dollars-as-text accessor for forms.
  def cost
    @cost_text || Money.decimal(cost_cents)
  end

  def cost=(dollars)
    cents = Money.parse_cents(dollars)
    @cost_text = cents ? nil : dollars.to_s
    self.cost_cents = cents if cents
  end

  # A gift is paid for by the giver and left out of the split.
  def gift
    !shared
  end
  alias_method :gift?, :gift

  def gift=(value)
    self.shared = !ActiveModel::Type::Boolean.new.cast(value)
  end

  private
    def cost_is_a_dollar_amount
      errors.add(:cost, "should be a dollar amount like 12.50") if @cost_text
    end

    def claimed_by_a_guest_of_this_party
      errors.add(:invitation, "must be a guest of this party") if invitation && invitation.event_id != event_id
    end

    def only_claimed_items_have_a_cost
      errors.add(:cost, "can only be logged once someone is bringing this") if !claimed? && cost_cents.to_i > 0
    end
end
