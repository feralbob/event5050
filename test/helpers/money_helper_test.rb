require "test_helper"

class MoneyHelperTest < ActionView::TestCase
  include MoneyHelper

  test "should format money with default currency" do
    money = Money.new(1234, "USD")

    formatted = format_money(money)

    assert_equal "$12.34", formatted
  end

  test "should format money with different currencies" do
    usd_money = Money.new(1234, "USD")
    eur_money = Money.new(1234, "EUR")
    gbp_money = Money.new(1234, "GBP")

    assert_equal "$12.34", format_money(usd_money)
    assert_equal "€12.34", format_money(eur_money)
    assert_equal "£12.34", format_money(gbp_money)
  end

  test "should format money with custom options" do
    money = Money.new(1234, "USD")

    # No cents
    assert_equal "$12", format_money(money, no_cents: true)

    # No currency symbol
    assert_equal "12.34", format_money(money, symbol: false)

    # Different separator
    assert_equal "$12,34", format_money(money, decimal_mark: ",")
  end

  test "should handle nil money gracefully" do
    formatted = format_money(nil)
    assert_equal "$0.00", formatted
  end

  test "should handle zero money" do
    money = Money.new(0, "USD")
    formatted = format_money(money)
    assert_equal "$0.00", formatted
  end

  test "should format money for different locales" do
    money = Money.new(123456, "USD") # $1,234.56

    # US format
    I18n.with_locale(:en) do
      assert_equal "$1,234.56", format_money(money)
    end
  end

  test "should format money with custom precision" do
    money = Money.new(123456, "USD") # $1,234.56

    # Show no decimal places (truncates cents)
    formatted = format_money(money, no_cents: true)
    assert_equal "$1,234", formatted

    # Default formatting
    formatted = format_money(money)
    assert_equal "$1,234.56", formatted
  end

  test "should provide money input formatting" do
    money = Money.new(1234, "USD")

    # For form inputs - no currency symbol, decimal format
    input_value = format_money_for_input(money)
    assert_equal "12.34", input_value
  end

  test "should handle nil for money input formatting" do
    input_value = format_money_for_input(nil)
    assert_equal "0.00", input_value
  end
end
