require "test_helper"

class CurrencyInheritanceTest < ActiveSupport::TestCase
  test "should inherit currency through complete chain: Organization -> Raffle -> Draw -> PricingTier -> Ticket" do
    # Create organization with EUR currency
    org = Organization.create!(name: "European Gaming Co", currency: "EUR")

    ActsAsTenant.with_tenant(org) do
      # Create supporting records
      jurisdiction = Jurisdiction.create!(name: "European Union", boundary: "POINT(0 0)")
      license = License.create!(
        organization: org,
        jurisdiction: jurisdiction,
        license_number: "EU-GAMING-2025",
        issued_at: Date.today,
        expires_at: 1.year.from_now,
        license_type: :single,
        requirements: {
          "license_fee_percentage" => 3.5,
          "minimum_age" => 18
        }
      )

      # Create raffle - should inherit EUR from organization
      raffle = Raffle.create!(
        organization: org,
        license: license,
        name: "New Year Grand Draw",
        description: "Annual grand draw with amazing prizes"
      )

      # Verify raffle inherited currency
      assert_equal "EUR", raffle.currency
      assert_equal "€", Money::Currency.new(raffle.currency).symbol

      # Create draw - should inherit EUR from raffle
      draw = Draw.create!(
        raffle: raffle,
        draw_date: Date.today + 1.month,
        ticket_sales_start_at: Time.current,
        ticket_sales_end_at: Time.current + 3.weeks,
        status: "active"
      )

      # Verify draw inherited currency
      assert_equal "EUR", draw.currency
      # Currency is stored as string, verify it's valid
      assert_nothing_raised { Money::Currency.new(draw.currency) }

      # Create pricing tier - should inherit EUR from raffle
      pricing_tier = PricingTier.create!(
        raffle: raffle,
        name: "Single Ticket",
        code: "single",
        ticket_quantity: 1,
        total_price_cents: 500,  # €5.00
        display_order: 1
      )

      # Verify pricing tier inherited currency
      assert_equal "EUR", pricing_tier.currency
      assert_equal Money.new(500, "EUR"), pricing_tier.total_price

      # Create customer
      customer = Customer.create!(
        first_name: "Marie",
        last_name: "Dubois",
        email: "marie.dubois@example.fr",
        phone: "+33123456789"
      )

      # Create ticket purchase
      ticket_purchase = TicketPurchase.create!(
        draw: draw,
        customer: customer,
        pricing_tier: pricing_tier,
        total_amount_cents: 500,
        currency: "EUR",
        purchase_date: Time.current
      )

      # Verify ticket purchase uses correct currency
      assert_equal "EUR", ticket_purchase.currency
      assert_equal Money.new(500, "EUR"), ticket_purchase.total_amount

      # Create ticket - should inherit EUR from draw
      ticket = Ticket.create!(
        draw: draw,
        customer: customer,
        pricing_tier: pricing_tier,
        ticket_purchase: ticket_purchase,
        ticket_number: "EUR-NEW-001"
      )

      # Verify ticket inherited currency through the chain
      assert_equal "EUR", ticket.currency
      # Currency is stored as string, verify it's valid
      assert_nothing_raised { Money::Currency.new(ticket.currency) }
      assert_equal "€", Money::Currency.new(ticket.currency).symbol

      # Verify effective price calculation uses correct currency
      assert_equal Money.new(500, "EUR"), ticket.effective_price
      assert_equal "EUR", ticket.effective_price.currency.to_s

      # Test formatted price display
      assert_match(/5/, ticket.formatted_price)

      # Test service layer integration with EUR
      draw.update!(total_revenue_cents: 50000)  # €500.00 total revenue

      # Test FeeCalculator with EUR currency
      fee_calculator = FeeCalculator.new(draw.total_revenue, license_requirements: license.requirements)
      platform_fee = fee_calculator.platform_fee
      license_fee = fee_calculator.license_fee

      assert_equal "EUR", platform_fee.currency.to_s
      assert_equal "EUR", license_fee.currency.to_s
      assert_instance_of Money::Currency, platform_fee.currency
      assert_instance_of Money::Currency, license_fee.currency

      # Test PrizePoolDistributor with EUR currency
      distributor = PrizePoolDistributor.new(draw, draw.total_revenue, license_requirements: license.requirements)
      distribution = distributor.calculate_distribution

      assert_equal "EUR", distribution[:main_prize].currency.to_s
      assert_equal "EUR", distribution[:platform_fee].currency.to_s
      assert_equal "EUR", distribution[:license_fee].currency.to_s
      assert_equal "EUR", distribution[:organization_share].currency.to_s

      # Verify all distributed amounts are Money::Currency objects
      assert_instance_of Money::Currency, distribution[:main_prize].currency
      assert_instance_of Money::Currency, distribution[:platform_fee].currency
      assert_instance_of Money::Currency, distribution[:license_fee].currency
      assert_instance_of Money::Currency, distribution[:organization_share].currency

      # Test prize pool calculation stores currency information
      draw.calculate_prize_pool_with_services!(license_requirements: license.requirements)

      assert_equal "EUR", draw.prize_pool["currency"]
      assert draw.prize_pool["main_prize_cents"] > 0
      assert draw.prize_pool["platform_fee_cents"] > 0
      assert draw.prize_pool["license_fee_cents"] > 0
    end
  end

  test "should support multiple currencies in same system" do
    # Create organizations with different currencies
    org_usd = Organization.create!(name: "American Gaming", currency: "USD")
    org_gbp = Organization.create!(name: "British Gaming", currency: "GBP")
    org_jpy = Organization.create!(name: "Japanese Gaming", currency: "JPY")

    organizations = [
      { org: org_usd, currency: "USD", symbol: "$" },
      { org: org_gbp, currency: "GBP", symbol: "£" },
      { org: org_jpy, currency: "JPY", symbol: "¥" }
    ]

    organizations.each do |org_data|
      ActsAsTenant.with_tenant(org_data[:org]) do
        jurisdiction = Jurisdiction.create!(
          name: "#{org_data[:currency]} Jurisdiction",
          boundary: "POINT(0 0)"
        )
        license = License.create!(
          organization: org_data[:org],
          jurisdiction: jurisdiction,
          license_number: "#{org_data[:currency]}-LICENSE-001",
          issued_at: Date.today,
          expires_at: 1.year.from_now,
          license_type: :single
        )

        raffle = Raffle.create!(
          organization: org_data[:org],
          license: license,
          name: "#{org_data[:currency]} Raffle"
        )

        # Verify each organization's raffle uses its currency
        assert_equal org_data[:currency], raffle.currency
        assert_equal org_data[:symbol], Money::Currency.new(raffle.currency).symbol

        draw = Draw.create!(
          raffle: raffle,
          draw_date: Date.today + 1.week,
          ticket_sales_start_at: Time.current,
          ticket_sales_end_at: Time.current + 6.days,
          status: "active"
        )

        # Verify draw inherits correct currency
        assert_equal org_data[:currency], draw.currency
        assert_equal org_data[:symbol], Money::Currency.new(draw.currency).symbol
      end
    end
  end

  test "should handle currency override scenarios" do
    # Create organization with default USD
    org = Organization.create!(name: "Multi-Currency Org", currency: "USD")

    ActsAsTenant.with_tenant(org) do
      jurisdiction = Jurisdiction.create!(name: "Global", boundary: "POINT(0 0)")
      license = License.create!(
        organization: org,
        jurisdiction: jurisdiction,
        license_number: "GLOBAL-001",
        issued_at: Date.today,
        expires_at: 1.year.from_now,
        license_type: :single
      )

      # Create raffle that overrides organization currency
      raffle = Raffle.create!(
        organization: org,
        license: license,
        name: "Special CAD Raffle",
        currency: "CAD"  # Override USD with CAD
      )

      # Verify override works
      assert_equal "USD", org.currency
      assert_equal "CAD", raffle.currency

      # Draw should inherit CAD from raffle, not USD from organization
      draw = Draw.create!(
        raffle: raffle,
        draw_date: Date.today + 1.week,
        ticket_sales_start_at: Time.current,
        ticket_sales_end_at: Time.current + 6.days,
        status: "active"
      )

      assert_equal "CAD", draw.currency

      # Pricing tier should inherit CAD from raffle
      pricing_tier = PricingTier.create!(
        raffle: raffle,
        name: "CAD Single",
        code: "cad_single",
        ticket_quantity: 1,
        total_price_cents: 1000  # $10.00 CAD
      )

      assert_equal "CAD", pricing_tier.currency

      # But pricing tier can override raffle currency too
      eur_pricing_tier = PricingTier.create!(
        raffle: raffle,
        name: "EUR Premium",
        code: "eur_premium",
        ticket_quantity: 1,
        total_price_cents: 800,  # €8.00
        currency: "EUR"  # Override CAD with EUR
      )

      assert_equal "CAD", raffle.currency
      assert_equal "EUR", eur_pricing_tier.currency
      assert_equal "€", Money::Currency.new(eur_pricing_tier.currency).symbol
    end
  end
end
