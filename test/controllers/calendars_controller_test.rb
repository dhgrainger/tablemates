require "test_helper"

class CalendarsControllerTest < ActionDispatch::IntegrationTest
  setup { @event = events(:dinner) }

  test "a guest downloads the party as an .ics file" do
    visit_as_guest invitations(:bea)
    get party_calendar_path(@event, format: :ics)

    assert_response :success
    assert_equal "text/calendar", response.media_type
    assert_match "dinner-at-alex-s.ics", response.headers["Content-Disposition"]
    assert_includes response.body, "SUMMARY:Dinner at Alex's"
  end

  test "strangers and other parties' guests can't" do
    get party_calendar_path(@event, format: :ics)
    assert_response :not_found

    visit_as_guest invitations(:eve)
    get party_calendar_path(@event, format: :ics)
    assert_response :not_found
  end

  test "the party page links to both calendar options, the invite page to neither" do
    visit_as_guest invitations(:bea)
    get party_path(@event)
    assert_select "#party_actions a[href=?]", party_calendar_path(@event, format: :ics)
    assert_select "#party_actions a[href^='https://calendar.google.com/calendar/render']"

    get invite_path(events(:brunch).invite_token)
    assert_select "#party_actions", count: 0
  end
end
