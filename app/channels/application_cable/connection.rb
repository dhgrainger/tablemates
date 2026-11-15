module ApplicationCable
  # Guests have no accounts, so the connection itself is open to anyone. The
  # only channel is Turbo::StreamsChannel, which authorises each subscription
  # by its signed stream name — and those are only rendered into pages the
  # viewer was already allowed to see.
  class Connection < ActionCable::Connection::Base
  end
end
