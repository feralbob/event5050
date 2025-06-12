require "test_helper"

class MoneyAggregatorTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @raffle = raffles(:one)
    @draw = draws(:one)
    ActsAsTenant.current_tenant = @organization
    
    # Create some tickets with different prices
    @purchaser1 = TicketPurchaser.create!(first_name: "John", last_name: "Doe", email: "john@test.com", phone: "555-0001")
    @purchaser2 = TicketPurchaser.create!(first_name: "Jane", last_name: "Smith", email: "jane@test.com", phone: "555-0002")
    
    @tickets = [
      Ticket.create!(draw: @draw, ticket_purchaser: @purchaser1, ticket_number: "TKT001", price: Money.new(500, "USD")),
      Ticket.create!(draw: @draw, ticket_purchaser: @purchaser1, ticket_number: "TKT002", price: Money.new(750, "USD")),
      Ticket.create!(draw: @draw, ticket_purchaser: @purchaser2, ticket_number: "TKT003", price: Money.new(1000, "USD")),
      Ticket.create!(draw: @draw, ticket_purchaser: @purchaser2, ticket_number: "TKT004", price: Money.new(600, "USD"))
    ]
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "should sum ticket prices using money-collection gem" do
    aggregator = MoneyAggregator.new(@tickets)
    
    total = aggregator.total_revenue
    
    # $5.00 + $7.50 + $10.00 + $6.00 = $28.50
    expected_total = Money.new(2850, "USD")
    assert_equal expected_total, total
  end

  test "should calculate average ticket price" do
    aggregator = MoneyAggregator.new(@tickets)
    
    average = aggregator.average_ticket_price
    
    # $28.50 / 4 tickets = $7.125, rounded to $7.13
    expected_average = Money.new(713, "USD")
    assert_equal expected_average, average
  end

  test "should handle mixed currency scenarios" do
    # Create tickets with different currencies
    eur_tickets = [
      Ticket.create!(draw: @draw, ticket_purchaser: @purchaser1, ticket_number: "TKT005", price: Money.new(500, "EUR")),
      Ticket.create!(draw: @draw, ticket_purchaser: @purchaser2, ticket_number: "TKT006", price: Money.new(750, "EUR"))
    ]
    
    aggregator = MoneyAggregator.new(eur_tickets)
    
    total = aggregator.total_revenue
    assert_equal "EUR", total.currency.to_s
    assert_equal Money.new(1250, "EUR"), total
  end

  test "should provide financial reporting totals" do
    aggregator = MoneyAggregator.new(@tickets)
    
    report = aggregator.financial_summary
    
    assert_includes report.keys, :total_revenue
    assert_includes report.keys, :average_price
    assert_includes report.keys, :ticket_count
    assert_includes report.keys, :min_price
    assert_includes report.keys, :max_price
    assert_includes report.keys, :currency
    
    assert_equal 4, report[:ticket_count]
    assert_equal Money.new(500, "USD"), report[:min_price]
    assert_equal Money.new(1000, "USD"), report[:max_price]
  end

  test "should handle empty collection gracefully" do
    aggregator = MoneyAggregator.new([])
    
    total = aggregator.total_revenue
    average = aggregator.average_ticket_price
    
    assert_equal Money.new(0, "USD"), total
    assert_equal Money.new(0, "USD"), average
  end

  test "should group tickets by purchaser" do
    aggregator = MoneyAggregator.new(@tickets)
    
    by_purchaser = aggregator.group_by_purchaser
    
    assert_equal 2, by_purchaser.keys.length
    
    john_total = by_purchaser[@purchaser1][:total]
    jane_total = by_purchaser[@purchaser2][:total]
    
    # John: $5.00 + $7.50 = $12.50
    # Jane: $10.00 + $6.00 = $16.00
    assert_equal Money.new(1250, "USD"), john_total
    assert_equal Money.new(1600, "USD"), jane_total
  end

  test "should provide revenue by time period" do
    # Set creation times for tickets
    @tickets[0].update!(created_at: 2.days.ago)
    @tickets[1].update!(created_at: 1.day.ago)
    @tickets[2].update!(created_at: 1.day.ago)
    @tickets[3].update!(created_at: Time.current)
    
    aggregator = MoneyAggregator.new(@tickets)
    
    daily_revenue = aggregator.revenue_by_day
    
    assert daily_revenue.is_a?(Hash)
    assert daily_revenue.values.all? { |v| v.is_a?(Money) }
  end

  test "should calculate percentage breakdown" do
    aggregator = MoneyAggregator.new(@tickets)
    
    breakdown = aggregator.percentage_breakdown_by_purchaser
    
    # John: $12.50 / $28.50 = 43.86%
    # Jane: $16.00 / $28.50 = 56.14%
    john_percentage = breakdown[@purchaser1]
    jane_percentage = breakdown[@purchaser2]
    
    assert_in_delta 43.86, john_percentage, 0.1
    assert_in_delta 56.14, jane_percentage, 0.1
  end

  test "should handle single currency validation" do
    # Mix USD and EUR tickets
    mixed_tickets = @tickets + [
      Ticket.create!(draw: @draw, ticket_purchaser: @purchaser1, ticket_number: "TKT007", price: Money.new(500, "EUR"))
    ]
    
    aggregator = MoneyAggregator.new(mixed_tickets)
    
    assert_raises(MoneyAggregator::MixedCurrencyError) do
      aggregator.total_revenue
    end
  end

  test "should provide statistics for money amounts" do
    aggregator = MoneyAggregator.new(@tickets)
    
    stats = aggregator.price_statistics
    
    assert_includes stats.keys, :mean
    assert_includes stats.keys, :median
    assert_includes stats.keys, :mode
    assert_includes stats.keys, :standard_deviation
    
    # Median of [500, 600, 750, 1000] = (600 + 750) / 2 = 675
    assert_equal Money.new(675, "USD"), stats[:median]
  end
end