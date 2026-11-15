require "test_helper"

class UserTest < ActiveSupport::TestCase
  def build_user(**attrs)
    User.new({ name: "Bea", email_address: "bea@example.com", password: "secret-pass" }.merge(attrs))
  end

  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "requires a name and a valid, unique email" do
    assert build_user.valid?
    assert_not build_user(name: " ").valid?
    assert_not build_user(email_address: "nope").valid?
    assert_not build_user(email_address: users(:alex).email_address.upcase).valid?
  end

  test "requires a password of at least 8 characters" do
    assert_not build_user(password: "short").valid?
  end

  test "normalises venmo username by stripping whitespace and a leading @" do
    assert_equal "bea-cooks", build_user(venmo_username: "  @bea-cooks ").venmo_username
    assert_nil build_user(venmo_username: "  ").venmo_username
  end

  test "validates venmo username format" do
    assert build_user(venmo_username: "Bea_Cooks-22").valid?
    assert_not build_user(venmo_username: "bea").valid?
    assert_not build_user(venmo_username: "bea cooks").valid?
    assert_not build_user(venmo_username: "bea/../cooks").valid?
    assert_not build_user(venmo_username: "a" * 31).valid?
  end
end
