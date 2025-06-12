class PrizePoolDistributor
  DEFAULT_MAIN_PRIZE_PERCENTAGE = 50.0
  DEFAULT_MINIMUM_ORGANIZATION_PERCENTAGE = 0.0

  attr_reader :draw, :total_revenue, :license_requirements, :main_prize_percentage,
              :secondary_prizes, :minimum_organization_percentage, :platform_fee_percentage

  def initialize(draw, total_revenue,
                 license_requirements: {},
                 main_prize_percentage: DEFAULT_MAIN_PRIZE_PERCENTAGE,
                 secondary_prizes: [],
                 minimum_organization_percentage: DEFAULT_MINIMUM_ORGANIZATION_PERCENTAGE,
                 platform_fee_percentage: FeeCalculator::DEFAULT_PLATFORM_FEE_PERCENTAGE)
    @draw = draw
    @total_revenue = total_revenue
    @license_requirements = license_requirements
    @main_prize_percentage = main_prize_percentage
    @secondary_prizes = secondary_prizes
    @minimum_organization_percentage = minimum_organization_percentage
    @platform_fee_percentage = platform_fee_percentage
  end

  def calculate_distribution
    return zero_distribution if total_revenue.zero?

    fees = fee_calculator.calculate_all_fees
    net_revenue = total_revenue - fees[:total_fees]

    # Calculate secondary prizes first
    secondary_prize_total = Money.new(0, currency)
    secondary_prize_details = []

    secondary_prizes.each do |prize|
      amount = (net_revenue * (prize[:percentage] / 100)).round
      secondary_prize_total += amount
      secondary_prize_details << {
        name: prize[:name],
        percentage: prize[:percentage],
        amount: amount
      }
    end

    # Calculate main prize from remaining net revenue
    remaining_for_main_and_org = net_revenue - secondary_prize_total
    main_prize_amount = (remaining_for_main_and_org * (main_prize_percentage / 100)).round

    # Calculate organization share
    organization_share = remaining_for_main_and_org - main_prize_amount

    # Enforce minimum organization percentage if specified
    if minimum_organization_percentage > 0
      minimum_org_amount = (total_revenue * (minimum_organization_percentage / 100)).round
      if organization_share < minimum_org_amount
        # Reduce main prize to ensure minimum organization share
        adjustment = minimum_org_amount - organization_share
        main_prize_amount = [ main_prize_amount - adjustment, Money.new(0, currency) ].max
        organization_share = minimum_org_amount
      end
    end

    {
      main_prize: main_prize_amount,
      secondary_prizes: secondary_prize_details,
      platform_fee: fees[:platform_fee],
      license_fee: fees[:license_fee],
      organization_share: organization_share,
      total_distributed: main_prize_amount + secondary_prize_total + fees[:total_fees] + organization_share
    }
  end

  def audit_trail
    distribution = calculate_distribution
    fees = fee_calculator.fee_breakdown

    {
      gross_revenue: total_revenue,
      fee_breakdown: fees,
      net_revenue: fees[:net_revenue],
      prize_distribution: distribution,
      calculation_timestamp: Time.current,
      parameters: {
        main_prize_percentage: main_prize_percentage,
        secondary_prizes: secondary_prizes,
        minimum_organization_percentage: minimum_organization_percentage,
        license_requirements: license_requirements
      }
    }
  end

  private

  def fee_calculator
    @fee_calculator ||= FeeCalculator.new(
      total_revenue,
      platform_fee_percentage: platform_fee_percentage,
      license_requirements: license_requirements
    )
  end

  def currency
    total_revenue.currency
  end

  def zero_distribution
    {
      main_prize: Money.new(0, currency),
      secondary_prizes: [],
      platform_fee: Money.new(0, currency),
      license_fee: Money.new(0, currency),
      organization_share: Money.new(0, currency),
      total_distributed: Money.new(0, currency)
    }
  end
end
