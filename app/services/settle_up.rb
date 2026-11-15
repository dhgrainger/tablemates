# Turns balances into the fewest payments that settle everyone up.
#
#   Pass 1: pair any debtor and creditor with exactly equal amounts.
#   Pass 2: greedy — the largest debtor pays the largest creditor, repeat.
#
# That needs at most (n - 1) payments. Event-level options:
#
#   round_to_whole_dollars: every non-host balance is rounded to the nearest
#     dollar before pairing and the host's balance takes up the slack, so all
#     payments are whole dollars and the host absorbs the difference.
#   forgive_under_cents: payments smaller than this are dropped.
class SettleUp
  Payment = Data.define(:from, :to, :amount_cents)

  def self.for(event)
    new(shares: FairShares.for(event).shares, host: event.host_invitation,
      round_to_whole_dollars: event.round_to_whole_dollars, forgive_under_cents: event.forgive_under_cents)
  end

  def initialize(shares:, host: nil, round_to_whole_dollars: false, forgive_under_cents: 0)
    raise ArgumentError, "rounding needs a host to absorb the difference" if round_to_whole_dollars && host.nil?

    @balances = shares.to_h { |share| [ share.invitation, share.balance_cents ] }
    @host = host
    @round_to_whole_dollars = round_to_whole_dollars
    @forgive_under_cents = forgive_under_cents
  end

  def payments
    @payments ||= begin
      balances = @round_to_whole_dollars ? rounded(@balances) : @balances
      raise FairShares::ImbalanceError, "balances must sum to zero" unless balances.values.sum.zero?

      minimal_payments(balances)
        .reject { |payment| payment.amount_cents < @forgive_under_cents }
        .sort_by { |payment| [ payment.from.id, payment.to.id ] }
    end
  end

  private
    def rounded(balances)
      others = balances.except(@host).transform_values { |cents| round_to_dollar(cents) }
      others.merge(@host => -others.values.sum)
    end

    # Nearest dollar, halves away from zero — integer maths only.
    def round_to_dollar(cents)
      rounded = (cents.abs + 50) / 100 * 100
      cents.negative? ? -rounded : rounded
    end

    def minimal_payments(balances)
      debtors = balances.select { |_, cents| cents.negative? }.transform_values(&:abs)
      creditors = balances.select { |_, cents| cents.positive? }

      pair_exact_matches(debtors, creditors) + pay_greedily(debtors, creditors)
    end

    def pair_exact_matches(debtors, creditors)
      debtors.keys.sort_by(&:id).filter_map do |debtor|
        creditor = creditors.keys.sort_by(&:id).find { |candidate| creditors[candidate] == debtors[debtor] }
        next unless creditor

        creditors.delete(creditor)
        Payment.new(from: debtor, to: creditor, amount_cents: debtors.delete(debtor))
      end
    end

    def pay_greedily(debtors, creditors)
      payments = []

      until debtors.empty?
        debtor = largest(debtors)
        creditor = largest(creditors)
        amount = [ debtors[debtor], creditors[creditor] ].min

        payments << Payment.new(from: debtor, to: creditor, amount_cents: amount)
        debtors.delete(debtor) if (debtors[debtor] -= amount).zero?
        creditors.delete(creditor) if (creditors[creditor] -= amount).zero?
      end

      payments
    end

    # Largest amount first; ties go to the lowest id so results are stable.
    def largest(amounts)
      amounts.keys.min_by { |person| [ -amounts[person], person.id ] }
    end
end
