class CalendarsController < ApplicationController
  include PartyAccess

  def show
    calendar = EventCalendar.new(@event)
    send_data calendar.to_ics, type: "text/calendar; charset=utf-8", filename: calendar.filename, disposition: "attachment"
  end
end
