require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get new_registration_path
    assert_response :success
  end

  test "create signs the new host in" do
    assert_difference -> { User.count } => 1 do
      post registration_path, params: { user: {
        name: "Bea Baker", email_address: "bea@example.com", password: "secret-pass", venmo_username: "@bea-baker"
      } }
    end

    assert_redirected_to root_path
    assert cookies[:session_id]
    assert_equal "bea-baker", User.find_by!(email_address: "bea@example.com").venmo_username
  end

  test "create with invalid details re-renders the form" do
    assert_no_difference -> { User.count } do
      post registration_path, params: { user: { name: "", email_address: "nope", password: "short" } }
    end

    assert_response :unprocessable_entity
    assert_select "#form_errors"
  end
end
