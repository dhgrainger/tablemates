# Venmo is the only payment provider and has no API: we only ever build
# pre-filled links. Keep all Venmo URL knowledge in this helper.
module PaymentsHelper
  def venmo_pay_url(username:, amount_cents:, note:)
    params = { txn: "pay", recipients: username,
               amount: Money.decimal(amount_cents, delimiter: ""), note: note }.to_query
    "https://account.venmo.com/pay?#{params}"
  end

  def venmo_profile_url(username)
    "https://venmo.com/u/#{ERB::Util.url_encode(username)}"
  end

  # "🍝 Dinner at Alex's – Nov 22"
  def venmo_note(event)
    "🍝 #{event.title} – #{event.starts_at.strftime('%b %-d')}"
  end
end
