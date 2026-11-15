require "test_helper"

class EventCalendarTest < ActiveSupport::TestCase
  setup do
    @event = Event.new(id: 7, title: "Dinner; at Alex's, again", location: "12 Orchard Lane, Apt 3",
      description: "Line one\nLine two", starts_at: Time.utc(2026, 11, 22, 19, 0), updated_at: Time.utc(2026, 11, 1, 12))
  end

  test "builds a valid single-event calendar in UTC" do
    ics = EventCalendar.new(@event).to_ics

    assert ics.start_with?("BEGIN:VCALENDAR\r\n")
    assert ics.end_with?("END:VCALENDAR\r\n")
    assert_includes ics, "DTSTART:20261122T190000Z\r\n"
    assert_includes ics, "DTEND:20261122T220000Z\r\n"
    assert_includes ics, "UID:party-7@tablemates\r\n"
  end

  test "escapes text fields" do
    ics = EventCalendar.new(@event).to_ics

    assert_includes ics, "SUMMARY:Dinner\; at Alex's\\, again\r\n"
    assert_includes ics, "LOCATION:12 Orchard Lane\\, Apt 3\r\n"
    assert_includes ics, "DESCRIPTION:Line one\\nLine two\r\n"
  end

  test "folds long lines at 75 octets" do
    @event.description = "A very long description " * 20
    ics = EventCalendar.new(@event).to_ics

    assert ics.split("\r\n").all? { |line| line.bytesize <= 75 }
    assert_includes ics.gsub("\r\n ", ""), @event.description.strip
  end

  test "google calendar link" do
    uri = URI.parse(EventCalendar.new(@event).google_url)
    params = Rack::Utils.parse_query(uri.query)

    assert_equal "calendar.google.com", uri.host
    assert_equal "TEMPLATE", params["action"]
    assert_equal "Dinner; at Alex's, again", params["text"]
    assert_equal "20261122T190000Z/20261122T220000Z", params["dates"]
    assert_equal "12 Orchard Lane, Apt 3", params["location"]
  end
end
