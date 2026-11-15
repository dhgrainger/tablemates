module EventsHelper
  # "Sat, Nov 22 · 7:00 PM"
  def event_when(event)
    "#{event.starts_at.strftime('%a, %b %-d')} · #{event.starts_at.strftime('%-l:%M %p')}"
  end

  def money(cents)
    Money.format(cents)
  end

  def saved_attachment?(attachment)
    attachment.attached? && attachment.blob.persisted?
  end
end
