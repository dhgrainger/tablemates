module SessionTestHelper
  def sign_in_as(user)
    Current.session = user.sessions.create!

    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:session_id] = Current.session.id
      cookies["session_id"] = cookie_jar[:session_id]
    end
  end

  def sign_out
    Current.session&.destroy!
    cookies.delete("session_id")
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include SessionTestHelper
end

module GuestTestHelper
  # Opens the guest's personal link, which remembers them via the signed cookie.
  def visit_as_guest(invitation)
    get guest_access_path(invitation.access_token)
    assert_redirected_to party_path(invitation.event)
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include GuestTestHelper
end
