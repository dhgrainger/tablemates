require "test_helper"

class EventTest < ActiveSupport::TestCase
  def new_event(**attrs)
    users(:alex).hosted_events.new({ title: "Taco night", starts_at: 3.days.from_now }.merge(attrs))
  end

  test "generates an unguessable invite token" do
    event = new_event
    event.save!
    assert_operator event.invite_token.length, :>=, 24
    assert_not_equal event.invite_token, new_event.tap(&:save!).invite_token
  end

  test "the host gets an invitation and is attending" do
    event = new_event
    event.save!

    invitation = event.host_invitation
    assert invitation.host?
    assert invitation.rsvp_yes?
    assert_equal "Alex Host", invitation.guest_name
    assert_equal "alex-host", invitation.venmo_username
    assert_equal [ invitation ], event.attendees.to_a
  end

  test "requires a title and a start time" do
    assert_not new_event(title: " ").valid?
    assert_not new_event(starts_at: nil).valid?
  end

  test "starts in planning" do
    assert new_event.planning?
  end

  test "forgive_under is entered in dollars and stored in cents" do
    event = new_event(forgive_under: "2.50")
    assert_equal 250, event.forgive_under_cents
    assert event.valid?

    assert_not new_event(forgive_under: "lots").valid?
    assert_not new_event(forgive_under: "500").valid?
  end

  test "accepts an image as the cover" do
    event = new_event
    event.cover_image.attach(io: file_fixture("cover.png").open, filename: "cover.png")
    assert event.valid?, event.errors.full_messages.to_sentence
  end

  test "rejects a cover that isn't an image, whatever it claims to be" do
    event = new_event
    event.cover_image.attach(io: file_fixture("not_an_image.txt").open, filename: "cover.png", content_type: "image/png")
    assert_not event.valid?
    assert_includes event.errors[:cover_image].to_sentence, "must be a PNG"
  end

  test "rejects a cover that is too big" do
    event = new_event
    event.cover_image.attach(io: file_fixture("cover.png").open, filename: "cover.png")
    event.cover_image.blob.byte_size = 6.megabytes
    assert_not event.valid?
    assert_includes event.errors[:cover_image].to_sentence, "too big"
  end

  test "upcoming and past" do
    assert_includes Event.upcoming, events(:dinner)
    assert_includes Event.past, events(:old_bbq)
    assert_not_includes Event.upcoming, events(:old_bbq)
  end
end
