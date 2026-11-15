require "test_helper"

class MoneyTest < ActiveSupport::TestCase
  test "parses dollars text to integer cents" do
    assert_equal 1250, Money.parse_cents("12.50")
    assert_equal 1250, Money.parse_cents("12.5")
    assert_equal 1200, Money.parse_cents("12")
    assert_equal 120_000, Money.parse_cents(" $1,200.00 ")
    assert_equal 5, Money.parse_cents("0.05")
    assert_equal 1999, Money.parse_cents("19.99")
  end

  test "blank is zero" do
    assert_equal 0, Money.parse_cents("")
    assert_equal 0, Money.parse_cents(nil)
  end

  test "rejects anything that isn't a plain dollar amount" do
    [ "-5", "abc", "1.234", "1e3", "12.", ".5", "1.2.3", "99999999" ].each do |input|
      assert_nil Money.parse_cents(input), "expected #{input.inspect} to be rejected"
    end
  end

  test "formats cents without floats" do
    assert_equal "$0.00", Money.format(0)
    assert_equal "$0.05", Money.format(5)
    assert_equal "$33.34", Money.format(3334)
    assert_equal "$1,234.56", Money.format(123_456)
    assert_equal "-$5.00", Money.format(-500)
    assert_equal "25.00", Money.decimal(2500)
  end
end
