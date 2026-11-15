# Plain-Ruby stand-ins so the split maths is tested without the database.
module SettleUpTestHelper
  Person = Struct.new(:id, :name) do
    def to_s = name
  end
  Item = Struct.new(:invitation, :cost_cents, :shared)

  def people(*names)
    names.each_with_index.map { |name, index| Person.new(index + 1, name) }
  end

  def paid(person, cents, shared: true)
    Item.new(person, cents, shared)
  end

  def needed_item
    Item.new(nil, 0, true)
  end

  def settle(attendees, items, **options)
    shares = FairShares.new(attendees: attendees, contributions: items).shares
    SettleUp.new(shares: shares, **options).payments
  end

  # ["Bea -> Alex 2500", ...]
  def describe(payments)
    payments.map { |payment| "#{payment.from} -> #{payment.to} #{payment.amount_cents}" }
  end

  # Applies the payments to the balances; everyone left at zero means settled.
  def balances_after(shares, payments)
    balances = shares.to_h { |share| [ share.invitation, share.balance_cents ] }
    payments.each do |payment|
      balances[payment.from] += payment.amount_cents
      balances[payment.to] -= payment.amount_cents
    end
    balances
  end
end
