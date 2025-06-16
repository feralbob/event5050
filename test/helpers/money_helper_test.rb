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

  test "should provide short format for large amounts" do
    large_money = Money.new(1234567, "USD") # $12,345.67

    short_format = format_money_short(large_money)
    assert_equal "$12.3K", short_format

    very_large = Money.new(1234567890, "USD") # $12,345,678.90
    short_format = format_money_short(very_large)
    assert_equal "$12.3M", short_format
  end

  test "should format money as percentage" do
    money = Money.new(2500, "USD") # $25.00
    total = Money.new(10000, "USD") # $100.00

    percentage = format_money_percentage(money, total)
    assert_equal "25.0%", percentage
  end

  test "should format money difference" do
    old_money = Money.new(1000, "USD") # $10.00
    new_money = Money.new(1500, "USD") # $15.00

    difference = format_money_difference(old_money, new_money)
    assert_equal "+$5.00", difference

    # Negative difference
    difference = format_money_difference(new_money, old_money)
    assert_equal "-$5.00", difference
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

  test "should parse money from string" do
    # Basic parsing
    money = parse_money("12.34", "USD")
    assert_equal Money.new(1234, "USD"), money

    # With currency symbol
    money = parse_money("$12.34", "USD")
    assert_equal Money.new(1234, "USD"), money

    # With commas
    money = parse_money("$1,234.56", "USD")
    assert_equal Money.new(123456, "USD"), money
  end

  test "should handle invalid money strings" do
    money = parse_money("invalid", "USD")
    assert_equal Money.new(0, "USD"), money

    money = parse_money("", "USD")
    assert_equal Money.new(0, "USD"), money

    money = parse_money(nil, "USD")
    assert_equal Money.new(0, "USD"), money
  end

  test "should format money for CSV export" do
    money = Money.new(1234, "USD")

    csv_format = format_money_for_csv(money)
    assert_equal "12.34", csv_format
  end

  test "should provide money color classes for styling" do
    positive_money = Money.new(1000, "USD")
    negative_money = Money.new(-1000, "USD")
    zero_money = Money.new(0, "USD")

    assert_equal "money-positive", money_color_class(positive_money)
    assert_equal "money-negative", money_color_class(negative_money)
    assert_equal "money-zero", money_color_class(zero_money)
  end

  test "should format money range" do
    min_money = Money.new(500, "USD")
    max_money = Money.new(2000, "USD")

    range = format_money_range(min_money, max_money)
    assert_equal "$5.00 - $20.00", range
  end

  test "should format money with currency code" do
    money = Money.new(1000, "EUR")
    formatted = format_money_with_currency(money)
    assert_match /€10.00 EUR/, formatted
  end

  test "should determine if currency code should be shown" do
    usd_money = Money.new(1000, "USD")
    eur_money = Money.new(1000, "EUR")
    
    assert_not show_currency_code?(usd_money)  # USD is default
    assert show_currency_code?(eur_money)     # EUR is not default
  end
end
