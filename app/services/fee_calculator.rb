class FeeCalculator
  DEFAULT_PLATFORM_FEE_PERCENTAGE = 2.5

  attr_reader :total_revenue, :license_requirements, :platform_fee_percentage

  def initialize(total_revenue, platform_fee_percentage: DEFAULT_PLATFORM_FEE_PERCENTAGE, license_requirements: {})
    @total_revenue = total_revenue
    @platform_fee_percentage = platform_fee_percentage
    @license_requirements = license_requirements || {}
  end

  def platform_fee
    return Money.new(0, currency) if total_revenue.zero?

    fee = total_revenue * (platform_fee_percentage / 100)
    fee.round
  end

  def license_fee
    return Money.new(0, currency) if total_revenue.zero?

    license_fee_percentage = license_requirements["license_fee_percentage"] || 0
    fee = total_revenue * (license_fee_percentage / 100)
    fee.round
  end

  def organization_commission
    # Organizations get the remainder after fees and main prize
    # For now, return 0 as they get what's left after all other deductions
    Money.new(0, currency)
  end

  def calculate_all_fees
    platform = platform_fee
    license = license_fee
    organization = organization_commission

    total = platform + license + organization

    # Ensure total fees don't exceed revenue
    if total > total_revenue
      # Proportionally reduce fees
      reduction_factor = total_revenue.cents.to_f / total.cents.to_f
      platform = Money.new((platform.cents * reduction_factor).round, currency)
      license = Money.new((license.cents * reduction_factor).round, currency)
      organization = Money.new((organization.cents * reduction_factor).round, currency)
      total = platform + license + organization
    end

    {
      platform_fee: platform,
      license_fee: license,
      organization_commission: organization,
      total_fees: total
    }
  end

  def net_revenue_after_fees
    fees = calculate_all_fees
    total_revenue - fees[:total_fees]
  end

  def fee_breakdown
    fees = calculate_all_fees
    net = net_revenue_after_fees

    {
      gross_revenue: total_revenue,
      platform_fee: fees[:platform_fee],
      license_fee: fees[:license_fee],
      organization_commission: fees[:organization_commission],
      total_fees: fees[:total_fees],
      net_revenue: net,
      fee_percentages: {
        platform_fee: platform_fee_percentage,
        license_fee: license_requirements["license_fee_percentage"] || 0,
        organization_commission: 0
      }
    }
  end

  private

  def currency
    total_revenue.currency
  end
end
