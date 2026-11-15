require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # A phone-sized viewport: the app is designed mobile-first at 375px wide.
  driven_by :selenium, using: :headless_chrome, screen_size: [ 375, 812 ] do |options|
    # Chrome's password-manager and autofill popups sit on top of the page and
    # swallow the next click, which makes form submissions flaky.
    options.add_preference("credentials_enable_service", false)
    options.add_preference("profile.password_manager_enabled", false)
    options.add_preference("profile.password_manager_leak_detection", false)
    options.add_preference("autofill.profile_enabled", false)
    options.add_preference("autofill.credit_card_enabled", false)
  end

  def sign_in_host(user, password: "password")
    visit new_session_path
    fill_in "Email", with: user.email_address
    fill_in "Password", with: password
    click_button "Sign in"
    assert_text "Hi, #{user.name.split.first}"
  end
end
