require "test_helper"

class ContributionTest < ActiveSupport::TestCase
  setup { @event = events(:dinner) }

  def build(**attrs)
    @event.contributions.new({ name: "Garlic bread", invitation: invitations(:bea) }.merge(attrs))
  end

  test "defaults to a shared, free item in the catch-all category" do
    contribution = build
    assert contribution.valid?
    assert contribution.shared?
    assert_equal 0, contribution.cost_cents
    assert contribution.other?
  end

  test "requires a name and a known category" do
    assert_not build(name: "").valid?
    assert_not build(category: "weapons").valid?
  end

  test "cost is entered in dollars and stored as integer cents" do
    contribution = build(cost: "19.99")
    assert_equal 1999, contribution.cost_cents
    assert_kind_of Integer, contribution.cost_cents
    assert_equal "19.99", contribution.cost
  end

  test "rejects negative, absurd and non-numeric costs" do
    assert_not build(cost_cents: -1).valid?
    assert_not build(cost_cents: Money::MAX_CENTS + 1).valid?
    assert build(cost_cents: Money::MAX_CENTS).valid?

    contribution = build(cost: "twelve")
    assert_not contribution.valid?
    assert_equal "twelve", contribution.cost
    assert_equal 0, contribution.cost_cents

    assert_not build(cost: "-5").valid?
    assert_not build(cost: "12.345").valid?
  end

  test "an unclaimed item cannot carry a cost" do
    assert build(invitation: nil).valid?
    assert_not build(invitation: nil, cost_cents: 500).valid?
  end

  test "can only be claimed by a guest of the same party" do
    assert_not build(invitation: invitations(:eve)).valid?
  end

  test "gift is the inverse of shared" do
    contribution = build(gift: "1")
    assert_not contribution.shared?
    assert contribution.gift?
    contribution.gift = "0"
    assert contribution.shared?
  end

  test "editable by whoever is bringing it and by the host only" do
    wine = contributions(:wine)
    assert wine.editable_by?(invitations(:bea))
    assert wine.editable_by?(invitations(:alex_at_dinner))
    assert_not wine.editable_by?(invitations(:cal))
    assert_not wine.editable_by?(invitations(:sam_at_brunch))
    assert_not contributions(:salad).editable_by?(invitations(:bea))
  end

  test "receipts must be images within the size limit" do
    contribution = build
    contribution.receipt.attach(io: file_fixture("cover.png").open, filename: "receipt.png")
    assert contribution.valid?

    contribution = build
    contribution.receipt.attach(io: file_fixture("not_an_image.txt").open, filename: "receipt.png", content_type: "image/png")
    assert_not contribution.valid?

    contribution = build
    contribution.receipt.attach(io: file_fixture("cover.png").open, filename: "receipt.png")
    contribution.receipt.blob.byte_size = 11.megabytes
    assert_not contribution.valid?
  end

  test "the event's shared total leaves out gifts" do
    assert_equal 9000, @event.shared_total_cents
  end

  test "changing a contribution touches the event so the page refreshes" do
    assert_changes -> { @event.reload.updated_at } do
      contributions(:wine).update!(cost_cents: 3100)
    end
  end
end
