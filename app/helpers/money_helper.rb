module MoneyHelper
  # Leverage money-rails built-in formatting with sensible defaults
  def format_money(money, **options)
    return Money.new(0, MoneyRails.default_currency).format if money.nil?

    money.format(options)
  end

  # Format for form inputs (decimal without currency symbol)
  def format_money_for_input(money)
    return "0.00" if money.nil?

    money.format(symbol: false)
  end
end
