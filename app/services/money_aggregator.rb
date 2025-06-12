class MoneyAggregator
  class MixedCurrencyError < StandardError; end

  attr_reader :items

  def initialize(items)
    @items = Array(items)
  end

  def total_revenue
    return Money.new(0, default_currency) if items.empty?

    prices = extract_prices
    validate_single_currency!(prices)

    prices.sum
  end

  def average_ticket_price
    return Money.new(0, default_currency) if items.empty?

    total = total_revenue
    (total / items.count).round
  end

  def financial_summary
    return empty_summary if items.empty?

    prices = extract_prices
    total = total_revenue

    {
      total_revenue: total,
      average_price: average_ticket_price,
      ticket_count: items.count,
      min_price: prices.min,
      max_price: prices.max,
      currency: total.currency.to_s
    }
  end

  def group_by_purchaser
    return {} if items.empty?

    grouped = items.group_by(&:ticket_purchaser)
    result = {}

    grouped.each do |purchaser, tickets|
      prices = tickets.map(&:effective_price)
      result[purchaser] = {
        total: prices.sum,
        count: tickets.count,
        average: (prices.sum / tickets.count).round,
        tickets: tickets
      }
    end

    result
  end

  def revenue_by_day
    return {} if items.empty?

    grouped = items.group_by { |item| item.created_at.to_date }
    result = {}

    grouped.each do |date, tickets|
      result[date] = tickets.map(&:effective_price).sum
    end

    result
  end

  def percentage_breakdown_by_purchaser
    return {} if items.empty?

    total = total_revenue
    return {} if total.zero?

    by_purchaser = group_by_purchaser
    result = {}

    by_purchaser.each do |purchaser, data|
      percentage = (data[:total].cents.to_f / total.cents.to_f) * 100
      result[purchaser] = percentage.round(2)
    end

    result
  end

  def price_statistics
    return empty_statistics if items.empty?

    prices = extract_prices
    sorted_prices = prices.sort_by(&:cents)

    # Calculate median
    median = if sorted_prices.count.even?
      mid_index = sorted_prices.count / 2
      ((sorted_prices[mid_index - 1] + sorted_prices[mid_index]) / 2).round
    else
      sorted_prices[sorted_prices.count / 2]
    end

    # Calculate mode (most frequent price)
    price_counts = prices.group_by(&:cents).transform_values(&:count)
    max_count = price_counts.values.max
    mode_cents = price_counts.find { |cents, count| count == max_count }&.first
    mode = mode_cents ? Money.new(mode_cents, prices.first.currency) : prices.first

    # Calculate standard deviation
    mean = average_ticket_price
    variance = prices.sum { |price| (price.cents - mean.cents) ** 2 } / prices.count.to_f
    std_dev = Money.new(Math.sqrt(variance).round, mean.currency)

    {
      mean: mean,
      median: median,
      mode: mode,
      standard_deviation: std_dev,
      min: sorted_prices.first,
      max: sorted_prices.last
    }
  end

  private

  def extract_prices
    items.map(&:effective_price)
  end

  def validate_single_currency!(prices)
    return if prices.empty?

    currencies = prices.map { |p| p.currency.to_s }.uniq
    if currencies.count > 1
      raise MixedCurrencyError, "Cannot aggregate prices with different currencies: #{currencies.join(', ')}"
    end
  end

  def default_currency
    "USD"
  end

  def empty_summary
    {
      total_revenue: Money.new(0, default_currency),
      average_price: Money.new(0, default_currency),
      ticket_count: 0,
      min_price: Money.new(0, default_currency),
      max_price: Money.new(0, default_currency),
      currency: default_currency
    }
  end

  def empty_statistics
    zero_money = Money.new(0, default_currency)
    {
      mean: zero_money,
      median: zero_money,
      mode: zero_money,
      standard_deviation: zero_money,
      min: zero_money,
      max: zero_money
    }
  end
end
