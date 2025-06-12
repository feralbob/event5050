require "test_helper"

class PrizePoolDistributorTest < ActiveSupport::TestCase
  setup do
    @draw = draws(:one)
    @total_revenue = Money.new(10000, "USD") # $100.00
    @license_requirements = { "license_fee_percentage" => 2.35 }
  end

  test "should distribute prize pool with platform fee deduction" do
    distributor = PrizePoolDistributor.new(@draw, @total_revenue)

    distribution = distributor.calculate_distribution

    # Expected: $100 - $2.50 platform fee - $0 license fee = $97.50 net
    # Main prize: 50% of net = $48.75
    expected_main_prize = Money.new(4875, "USD")

    assert_equal expected_main_prize, distribution[:main_prize]
    assert distribution[:platform_fee] > Money.new(0, "USD")
  end

  test "should distribute prize pool with license fee deduction" do
    distributor = PrizePoolDistributor.new(@draw, @total_revenue, license_requirements: @license_requirements)

    distribution = distributor.calculate_distribution

    # Expected: $100 - $2.50 platform - $2.35 license = $95.15 net
    # Main prize: 50% of net = $47.58 (rounded)
    expected_main_prize = Money.new(4758, "USD")
    expected_license_fee = Money.new(235, "USD")

    assert_equal expected_main_prize, distribution[:main_prize]
    assert_equal expected_license_fee, distribution[:license_fee]
  end

  test "should calculate main prize as percentage after fees" do
    distributor = PrizePoolDistributor.new(@draw, @total_revenue,
                                          license_requirements: @license_requirements,
                                          main_prize_percentage: 60.0) # 60% instead of 50%

    distribution = distributor.calculate_distribution

    # Net revenue after fees: $95.15
    # Main prize: 60% of $95.15 = $57.09
    expected_main_prize = Money.new(5709, "USD")

    assert_equal expected_main_prize, distribution[:main_prize]
  end

  test "should handle insufficient funds scenarios" do
    small_revenue = Money.new(100, "USD") # $1.00
    distributor = PrizePoolDistributor.new(@draw, small_revenue, license_requirements: @license_requirements)

    distribution = distributor.calculate_distribution

    # With small revenue, fees might consume most/all of it
    # Main prize should never be negative
    assert distribution[:main_prize] >= Money.new(0, "USD")
    assert distribution[:organization_share] >= Money.new(0, "USD")
  end

  test "should maintain Money precision in all calculations" do
    # Use odd amounts that require precise calculations
    odd_revenue = Money.new(3333, "USD") # $33.33
    distributor = PrizePoolDistributor.new(@draw, odd_revenue, license_requirements: @license_requirements)

    distribution = distributor.calculate_distribution

    # All amounts should be properly rounded Money objects
    assert_instance_of Money, distribution[:main_prize]
    assert_instance_of Money, distribution[:platform_fee]
    assert_instance_of Money, distribution[:license_fee]
    assert_instance_of Money, distribution[:organization_share]

    # Total should reconcile
    total = distribution[:main_prize] + distribution[:platform_fee] +
            distribution[:license_fee] + distribution[:organization_share]
    assert_equal odd_revenue, total
  end

  test "should support secondary prizes" do
    secondary_prizes = [
      { name: "Early Bird", percentage: 5.0 }, # 5% of net revenue
      { name: "Second Place", percentage: 10.0 } # 10% of net revenue
    ]

    distributor = PrizePoolDistributor.new(@draw, @total_revenue,
                                          license_requirements: @license_requirements,
                                          secondary_prizes: secondary_prizes)

    distribution = distributor.calculate_distribution

    # Net revenue: $95.15
    # Early Bird: 5% = $4.76
    # Second Place: 10% = $9.52
    # Main prize: remaining percentage (35% of net since 50% - 15% secondary = 35%)

    assert_includes distribution.keys, :secondary_prizes
    assert_equal 2, distribution[:secondary_prizes].length

    early_bird = distribution[:secondary_prizes].find { |p| p[:name] == "Early Bird" }
    assert_equal Money.new(476, "USD"), early_bird[:amount]
  end

  test "should handle multi-currency distributions" do
    revenue_eur = Money.new(10000, "EUR") # €100.00
    distributor = PrizePoolDistributor.new(@draw, revenue_eur, license_requirements: @license_requirements)

    distribution = distributor.calculate_distribution

    assert_equal "EUR", distribution[:main_prize].currency.to_s
    assert_equal "EUR", distribution[:platform_fee].currency.to_s
    assert_equal "EUR", distribution[:license_fee].currency.to_s
  end

  test "should provide detailed audit trail" do
    distributor = PrizePoolDistributor.new(@draw, @total_revenue, license_requirements: @license_requirements)

    audit_trail = distributor.audit_trail

    assert_includes audit_trail.keys, :gross_revenue
    assert_includes audit_trail.keys, :fee_breakdown
    assert_includes audit_trail.keys, :net_revenue
    assert_includes audit_trail.keys, :prize_distribution
    assert_includes audit_trail.keys, :calculation_timestamp
  end

  test "should handle edge case of zero revenue" do
    distributor = PrizePoolDistributor.new(@draw, Money.new(0, "USD"))

    distribution = distributor.calculate_distribution

    assert_equal Money.new(0, "USD"), distribution[:main_prize]
    assert_equal Money.new(0, "USD"), distribution[:platform_fee]
    assert_equal Money.new(0, "USD"), distribution[:organization_share]
  end

  test "should enforce minimum organization share" do
    # Test scenario where fees would leave very little for organization
    high_fee_requirements = { "license_fee_percentage" => 40.0 }
    distributor = PrizePoolDistributor.new(@draw, @total_revenue,
                                          license_requirements: high_fee_requirements,
                                          minimum_organization_percentage: 10.0) # Minimum 10%

    distribution = distributor.calculate_distribution

    # Organization should get at least 10% of gross revenue
    minimum_org_share = Money.new(1000, "USD") # 10% of $100
    assert distribution[:organization_share] >= minimum_org_share
  end
end
