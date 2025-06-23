# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Disable tenant scoping for seeding
ActsAsTenant.without_tenant do
  # Create jurisdictions
  california = Jurisdiction.find_or_create_by!(
    name: "California",
    boundary: "POLYGON((-124.4 42.0, -124.4 32.5, -114.1 32.5, -114.1 42.0, -124.4 42.0))"
  )

  nevada = Jurisdiction.find_or_create_by!(
    name: "Nevada",
    boundary: "POLYGON((-120.0 42.0, -120.0 35.0, -114.0 35.0, -114.0 42.0, -120.0 42.0))"
  )

  # Create organizations
  org1 = Organization.find_or_create_by!(name: "Community Center Fundraising")
  org2 = Organization.find_or_create_by!(name: "Local Sports Club")

  # Create licenses
  license1 = License.find_or_create_by!(
    organization: org1,
    jurisdiction: california,
    license_number: "CA-2025-001",
    issued_at: Date.current,
    expires_at: Date.current + 1.year,
    license_type: :recurring,
    recurrence_rule: "FREQ=WEEKLY;BYDAY=FR",
    requirements: {
      "minimum_age" => 21,
      "geographic_restriction" => true,
      "license_fee_percentage" => 2.5
    }
  )

  license2 = License.find_or_create_by!(
    organization: org2,
    jurisdiction: nevada,
    license_number: "NV-2025-001",
    issued_at: Date.current,
    expires_at: Date.current + 6.months,
    license_type: :single,
    event_date: Date.current + 1.month,
    requirements: {
      "minimum_age" => 18,
      "geographic_restriction" => false,
      "license_fee_percentage" => 3.0
    }
  )

  # Create raffles
  raffle1 = Raffle.find_or_create_by!(
    organization: org1,
    license: license1,
    name: "Friday Night 50/50",
    description: "Weekly Friday night raffle to support community programs",
    status: :active,
    recurring: true,
    recurrence_rule: "FREQ=WEEKLY;BYDAY=FR"
  )

  raffle2 = Raffle.find_or_create_by!(
    organization: org2,
    license: license2,
    name: "Championship Game Special",
    description: "Special one-time raffle for the championship game",
    status: :draft,
    recurring: false
  )

  # Create draws
  draw1 = Draw.find_or_create_by!(
    raffle: raffle1,
    draw_date: Date.current + 1.week,
    ticket_sales_start_at: Time.current,
    ticket_sales_end_at: Time.current + 6.days,
    status: :active,
    total_revenue_cents: 0,
    prize_pool: { "main_prize" => { "percentage" => 50 } }
  )

  draw2 = Draw.find_or_create_by!(
    raffle: raffle2,
    draw_date: Date.current + 1.month,
    ticket_sales_start_at: Time.current + 3.weeks,
    ticket_sales_end_at: Time.current + 4.weeks,
    status: :scheduled,
    total_revenue_cents: 0,
    prize_pool: { "main_prize" => { "percentage" => 50 } }
  )

  # Create customers
  customer1 = Customer.find_or_create_by!(
    email: "john.doe@example.com"
  ) do |c|
    c.first_name = "John"
    c.last_name = "Doe"
    c.phone = "555-0123"
  end

  customer2 = Customer.find_or_create_by!(
    email: "jane.smith@example.com"
  ) do |c|
    c.first_name = "Jane"
    c.last_name = "Smith"
    c.phone = "555-0456"
  end

  # Create pricing tiers for raffle1
  single_tier = raffle1.pricing_tiers.find_or_create_by!(code: "single") do |pt|
    pt.name = "Single Ticket"
    pt.ticket_quantity = 1
    pt.total_price_cents = 500
    pt.display_order = 1
    pt.active = true
  end

  bundle_tier = raffle1.pricing_tiers.find_or_create_by!(code: "bundle_3") do |pt|
    pt.name = "3 Ticket Bundle"
    pt.ticket_quantity = 3
    pt.total_price_cents = 1000
    pt.display_order = 2
    pt.active = true
  end

  # Create pricing tiers for raffle2
  single_tier2 = raffle2.pricing_tiers.find_or_create_by!(code: "single") do |pt|
    pt.name = "Single Ticket"
    pt.ticket_quantity = 1
    pt.total_price_cents = 1000
    pt.display_order = 1
    pt.active = true
  end

  bundle_tier2 = raffle2.pricing_tiers.find_or_create_by!(code: "bundle_5") do |pt|
    pt.name = "5 Ticket Bundle"
    pt.ticket_quantity = 5
    pt.total_price_cents = 4000
    pt.display_order = 2
    pt.active = true
  end

  purchase1 = TicketPurchase.find_or_create_by!(
    draw: draw1,
    customer: customer1
  ) do |tp|
    tp.pricing_tier = single_tier
    tp.total_amount_cents = 500
    tp.currency = "USD"
    tp.purchase_date = Time.current
  end

  purchase2 = TicketPurchase.find_or_create_by!(
    draw: draw1,
    customer: customer2
  ) do |tp|
    tp.pricing_tier = bundle_tier
    tp.total_amount_cents = 1000
    tp.currency = "USD"
    tp.purchase_date = Time.current
  end

  ticket1 = Ticket.find_or_create_by!(
    draw: draw1,
    customer: customer1,
    ticket_number: "FRI-001-ABC",
    ticket_purchase: purchase1,
    pricing_tier: purchase1.pricing_tier,
    status: :active,
    purchase_metadata: {
      "purchase_time" => Time.current.iso8601,
      "ip_address" => "192.168.1.100"
    }
  )

  ticket2 = Ticket.find_or_create_by!(
    draw: draw1,
    customer: customer2,
    ticket_number: "FRI-002-DEF",
    ticket_purchase: purchase2,
    pricing_tier: purchase2.pricing_tier,
    status: :active,
    purchase_metadata: {
      "purchase_time" => Time.current.iso8601,
      "ip_address" => "192.168.1.101"
    }
  )

  puts "✅ Seed data created successfully!"
  puts "📊 Created: #{Organization.count} organizations, #{License.count} licenses, #{Raffle.count} raffles, #{Draw.count} draws, #{Ticket.count} tickets"
end
