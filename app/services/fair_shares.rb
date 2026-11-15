# Works out what each person paid, what their fair share is, and so their
# balance (positive = they are owed, negative = they owe).
#
# Pure integer-cents arithmetic. Only needs objects that respond like
# Invitation (#id) and Contribution (#invitation, #cost_cents, #shared).
class FairShares
  class ImbalanceError < StandardError; end

  Share = Data.define(:invitation, :paid_cents, :share_cents) do
    def balance_cents
      paid_cents - share_cents
    end
  end

  attr_reader :total_cents, :attendee_count, :shares

  def self.for(event)
    new(attendees: event.attendees.to_a, contributions: event.contributions.includes(:invitation).to_a)
  end

  # attendees: the people splitting the bill (RSVP yes).
  # contributions: everything on the board; gifts and unclaimed items are ignored.
  def initialize(attendees:, contributions:)
    attendees = attendees.sort_by(&:id)
    paid = paid_by_person(contributions)

    @attendee_count = attendees.size
    @total_cents = attendees.empty? ? 0 : paid.values.sum
    @shares = attendees.empty? ? [] : build_shares(attendees, paid)

    assert_balanced!
  end

  def share_for(invitation)
    shares.find { |share| share.invitation == invitation }
  end

  private
    def paid_by_person(contributions)
      contributions.each_with_object(Hash.new(0)) do |contribution, paid|
        next unless contribution.shared && contribution.invitation
        paid[contribution.invitation] += contribution.cost_cents
      end
    end

    def build_shares(attendees, paid)
      # Split without losing pennies: the first `remainder` attendees (by id)
      # pay one extra cent.
      base, remainder = total_cents.divmod(attendees.size)
      owed = attendees.each_with_index.to_h { |attendee, index| [ attendee, base + (index < remainder ? 1 : 0) ] }

      # Someone who paid for a shared item but isn't attending has no share,
      # so they're simply reimbursed.
      everyone = (attendees + paid.keys).uniq.sort_by(&:id)
      everyone.map { |person| Share.new(invitation: person, paid_cents: paid[person], share_cents: owed.fetch(person, 0)) }
    end

    def assert_balanced!
      sum = shares.sum(&:balance_cents)
      raise ImbalanceError, "balances sum to #{sum} cents, expected 0" unless sum.zero?
    end
end
