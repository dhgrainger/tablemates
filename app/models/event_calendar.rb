# Calendar exports for a party: an .ics file and an "Add to Google Calendar" link.
class EventCalendar
  DURATION = 3.hours
  STAMP = "%Y%m%dT%H%M%SZ"

  def initialize(event, url: nil)
    @event = event
    @url = url
  end

  def to_ics
    lines = [
      "BEGIN:VCALENDAR",
      "VERSION:2.0",
      "PRODID:-//Tablemates//Party//EN",
      "CALSCALE:GREGORIAN",
      "METHOD:PUBLISH",
      "BEGIN:VEVENT",
      "UID:party-#{@event.id}@tablemates",
      "DTSTAMP:#{stamp(@event.updated_at)}",
      "DTSTART:#{stamp(starts_at)}",
      "DTEND:#{stamp(ends_at)}",
      "SUMMARY:#{escape(@event.title)}",
      ("LOCATION:#{escape(@event.location)}" if @event.location.present?),
      ("DESCRIPTION:#{escape(details)}" if details.present?),
      "END:VEVENT",
      "END:VCALENDAR"
    ]
    lines.compact.map { |line| fold(line) }.join("\r\n") + "\r\n"
  end

  def google_url
    params = {
      action: "TEMPLATE", text: @event.title, dates: "#{stamp(starts_at)}/#{stamp(ends_at)}",
      details: details.presence, location: @event.location.presence
    }.compact
    "https://calendar.google.com/calendar/render?#{params.to_query}"
  end

  def filename
    "#{@event.title.parameterize.presence || 'party'}.ics"
  end

  private
    def starts_at = @event.starts_at
    def ends_at = @event.starts_at + DURATION

    def details
      [ @event.description.presence, @url ].compact.join("\n\n")
    end

    def stamp(time)
      time.utc.strftime(STAMP)
    end

    # RFC 5545 text escaping.
    def escape(text)
      text.to_s.gsub("\\", "\\\\\\\\").gsub(";", "\;").gsub(",", "\\,").gsub(/\r?\n/, "\\n")
    end

    # RFC 5545 line folding: lines over 75 octets continue on the next line
    # after a single space.
    def fold(line)
      chunks = []
      current = +""
      line.each_char do |char|
        if (current + char).bytesize > (chunks.empty? ? 75 : 74)
          chunks << current
          current = +""
        end
        current << char
      end
      (chunks << current).join("\r\n ")
    end
end
