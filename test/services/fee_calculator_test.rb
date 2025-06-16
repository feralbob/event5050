require "test_helper"

class FeeCalculatorTest < ActiveSupport::TestCase
  setup do
    @draw = draws(:one)
    @total_revenue = Money.new(10000, "USD") # $100.00
  end

  test "should calculate platform fee percentage" do
    calculator = FeeCalculator.new(@total_revenue)

    # Default platform fee should be 2.5%
    expected_platform_fee = Money.new(250, "USD") # 2.5% of $100 = $2.50
    assert_equal expected_platform_fee, calculator.platform_fee
  end

  test "should calculate license fee based on jurisdiction requirements" do
    # License with 2.35% fee requirement (from specification)
    license_requirements = { "license_fee_percentage" => 2.35 }

    calculator = FeeCalculator.new(@total_revenue, license_requirements: license_requirements)

    expected_license_fee = Money.new(235, "USD") # 2.35% of $100 = $2.35
    assert_equal expected_license_fee, calculator.license_fee
  end

  test "should calculate organization commission" do
    calculator = FeeCalculator.new(@total_revenue)

    # Default organization commission should be 0% (they get remainder after fees and main prize)
    expected_commission = Money.new(0, "USD")
    assert_equal expected_commission, calculator.organization_commission
  end

  test "should handle multiple fee types in correct order" do
    license_requirements = { "license_fee_percentage" => 2.35 }
    calculator = FeeCalculator.new(@total_revenue, license_requirements: license_requirements)

    fees = calculator.calculate_all_fees

    assert_includes fees.keys, :platform_fee
    assert_includes fees.keys, :license_fee
    assert_includes fees.keys, :organization_commission
    assert_includes fees.keys, :total_fees
  end

  test "should ensure fees don't exceed total revenue" do
    # Test with extremely high fee percentages
    license_requirements = { "license_fee_percentage" => 95.0 }
    calculator = FeeCalculator.new(@total_revenue,
                                  platform_fee_percentage: 10.0,
                                  license_requirements: license_requirements)

    fees = calculator.calculate_all_fees

    # Total fees should not exceed total revenue
    assert fees[:total_fees] <= @total_revenue
  end

  test "should round fees appropriately using Money rounding rules" do
    # Use amount that will require rounding
    revenue = Money.new(3333, "USD") # $33.33
    license_requirements = { "license_fee_percentage" => 2.35 }

    calculator = FeeCalculator.new(revenue, license_requirements: license_requirements)

    # 2.35% of $33.33 = $0.783255, should round to $0.78
    expected_license_fee = Money.new(78, "USD")
    assert_equal expected_license_fee, calculator.license_fee
  end

  test "should handle zero revenue gracefully" do
    calculator = FeeCalculator.new(Money.new(0, "USD"))

    fees = calculator.calculate_all_fees

    assert_equal Money.new(0, "USD"), fees[:platform_fee]
    assert_equal Money.new(0, "USD"), fees[:license_fee]
    assert_equal Money.new(0, "USD"), fees[:total_fees]
  end

  test "should support different currencies" do
    revenue_eur = Money.new(10000, "EUR") # €100.00
    license_requirements = { "license_fee_percentage" => 2.35 }

    calculator = FeeCalculator.new(revenue_eur, license_requirements: license_requirements)

    assert_equal "EUR", calculator.platform_fee.currency.to_s
    assert_equal "EUR", calculator.license_fee.currency.to_s

    # Test that currency objects are properly handled
    assert_instance_of Money::Currency, calculator.platform_fee.currency
    assert_instance_of Money::Currency, calculator.license_fee.currency
  end

  test "should calculate net revenue after all fees" do
    license_requirements = { "license_fee_percentage" => 2.35 }
    calculator = FeeCalculator.new(@total_revenue, license_requirements: license_requirements)

    fees = calculator.calculate_all_fees
    net_revenue = calculator.net_revenue_after_fees

    expected_net = @total_revenue - fees[:total_fees]
    assert_equal expected_net, net_revenue
  end

  test "should provide fee breakdown for audit trail" do
    license_requirements = { "license_fee_percentage" => 2.35 }
    calculator = FeeCalculator.new(@total_revenue, license_requirements: license_requirements)

    breakdown = calculator.fee_breakdown

    assert_includes breakdown.keys, :gross_revenue
    assert_includes breakdown.keys, :platform_fee
    assert_includes breakdown.keys, :license_fee
    assert_includes breakdown.keys, :total_fees
    assert_includes breakdown.keys, :net_revenue
    assert_includes breakdown.keys, :fee_percentages
  end
end
