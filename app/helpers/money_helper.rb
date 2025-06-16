module MoneyHelper
  # Leverage money-rails built-in formatting with sensible defaults
  def format_money(money, **options)
    return Money.new(0, MoneyRails.default_currency).format if money.nil?

    money.format(options)
  end

  # Custom formatting for large amounts (K/M notation)
  def format_money_short(money)
    return "$0" if money.nil? || money.zero?

    amount = money.cents.abs

    if amount >= 1_000_000_00 # $1M+
      "#{money.currency.symbol}#{(amount / 1_000_000_00.0).round(1)}M"
    elsif amount >= 1_000_00 # $1K+
      "#{money.currency.symbol}#{(amount / 1_000_00.0).round(1)}K"
    else
      money.format
    end
  end

  # Calculate percentage of money amounts
  def format_money_percentage(money, total)
    return "0.0%" if total.nil? || total.zero? || money.nil?

    percentage = (money.cents.to_f / total.cents.to_f) * 100
    "#{percentage.round(1)}%"
  end

  # Show difference between two money amounts
  def format_money_difference(old_money, new_money)
    return Money.new(0, MoneyRails.default_currency).format if old_money.nil? || new_money.nil?

    difference = new_money - old_money
    if difference.positive?
      "+#{difference.format}"
    elsif difference.negative?
      "-#{difference.abs.format}"
    else
      difference.format
    end
  end

  # Format for form inputs (decimal without currency symbol)
  def format_money_for_input(money)
    return "0.00" if money.nil?

    money.format(symbol: false)
  end

  # Parse money from string with error handling
  def parse_money(value, currency = MoneyRails.default_currency)
    return Money.new(0, currency) if value.blank?

    begin
      # Remove currency symbols and commas, then create Money object
      cleaned_value = value.to_s.gsub(/[$,€£]/, "")
      amount_in_cents = (cleaned_value.to_f * 100).round
      Money.new(amount_in_cents, currency)
    rescue StandardError
      Money.new(0, currency)
    end
  end

  # Format for CSV export (no currency symbol)
  def format_money_for_csv(money)
    return "0.00" if money.nil?

    money.format(symbol: false)
  end

  # CSS class helper for styling
  def money_color_class(money)
    return "money-zero" if money.nil? || money.zero?

    money.positive? ? "money-positive" : "money-negative"
  end

  # Format money range
  def format_money_range(min_money, max_money)
    default_money = Money.new(0, MoneyRails.default_currency)
    min_formatted = min_money&.format || default_money.format
    max_formatted = max_money&.format || default_money.format

    "#{min_formatted} - #{max_formatted}"
  end

  # Format money with currency code for international display
  def format_money_with_currency(money)
    return Money.new(0, MoneyRails.default_currency).format if money.nil?
    
    "#{money.format} #{money.currency.iso_code}"
  end

  # Check if organization uses non-default currency
  def show_currency_code?(money)
    return false if money.nil?
    
    money.currency.iso_code != MoneyRails.default_currency.to_s
  end
end
