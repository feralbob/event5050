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
    recurrence_rule: "FREQ=WEEKLY;BYDAY=FR",
    ticket_pricing: [
      { "quantity" => 1, "price_cents" => 500, "currency" => "USD" },
      { "quantity" => 3, "price_cents" => 1000, "currency" => "USD" },
      { "quantity" => 10, "price_cents" => 2500, "currency" => "USD" }
    ]
  )

  raffle2 = Raffle.find_or_create_by!(
    organization: org2,
    license: license2,
    name: "Championship Game Special",
    description: "Special one-time raffle for the championship game",
    status: :draft,
    recurring: false,
    ticket_pricing: [
      { "quantity" => 1, "price_cents" => 1000, "currency" => "USD" },
      { "quantity" => 5, "price_cents" => 4000, "currency" => "USD" }
    ]
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

  # Create ticket purchasers
  purchaser1 = TicketPurchaser.find_or_create_by!(
    email: "john.doe@example.com"
  ) do |tp|
    tp.first_name = "John"
    tp.last_name = "Doe"
    tp.phone = "555-0123"
  end

  purchaser2 = TicketPurchaser.find_or_create_by!(
    email: "jane.smith@example.com"
  ) do |tp|
    tp.first_name = "Jane"
    tp.last_name = "Smith" 
    tp.phone = "555-0456"
  end

  # Create some tickets
  ticket1 = Ticket.find_or_create_by!(
    draw: draw1,
    ticket_purchaser: purchaser1,
    ticket_number: "FRI-001-ABC",
    price_cents: 500,
    status: :active,
    purchase_metadata: {
      "purchase_time" => Time.current.iso8601,
      "ip_address" => "192.168.1.100"
    }
  )

  ticket2 = Ticket.find_or_create_by!(
    draw: draw1,
    ticket_purchaser: purchaser2,
    ticket_number: "FRI-002-DEF", 
    price_cents: 1000,
    status: :active,
    purchase_metadata: {
      "purchase_time" => Time.current.iso8601,
      "ip_address" => "192.168.1.101"
    }
  )

  puts "✅ Seed data created successfully!"
  puts "📊 Created: #{Organization.count} organizations, #{License.count} licenses, #{Raffle.count} raffles, #{Draw.count} draws, #{Ticket.count} tickets"
end
