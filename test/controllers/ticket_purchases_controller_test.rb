require "test_helper"

class TicketPurchasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = organizations(:one)
    @jurisdiction = jurisdictions(:one)
    @license = licenses(:one)
    @raffle = raffles(:one)
    @draw = draws(:one)
  end

  test "should get index with available draws" do
    get ticket_purchases_url
    assert_response :success
    assert_select "h1", "Available Draws"
  end

  test "should show draw details and purchase form" do
    get ticket_purchase_url(@draw)
    assert_response :success
    assert_select "h1", @draw.raffle.name
    assert_select "form#new_ticket_purchase"
  end

  test "should not show purchase form for closed draw" do
    @draw.update!(status: :closed)
    get ticket_purchase_url(@draw)
    assert_response :success
    assert_select "form#new_ticket_purchase", false
    assert_select ".alert", /Sales have ended/
  end

  test "should create ticket purchase" do
    assert_difference("Ticket.count") do
      post ticket_purchases_url, params: {
        draw_id: @draw.id,
        ticket_purchase: {
          ticket_purchaser_attributes: {
            first_name: "John",
            last_name: "Doe",
            email: "john@example.com",
            phone: "555-1234"
          },
          quantity: 1,
          price_tier: "single"
        }
      }
    end

    assert_redirected_to confirmation_ticket_purchase_url(Ticket.last)
    follow_redirect!
    assert_select ".alert-success", /Thank you for your purchase/
  end

  test "should create multiple tickets for quantity purchase" do
    assert_difference("Ticket.count", 3) do
      post ticket_purchases_url, params: {
        draw_id: @draw.id,
        ticket_purchase: {
          ticket_purchaser_attributes: {
            first_name: "Jane",
            last_name: "Smith",
            email: "jane@example.com",
            phone: "555-5678"
          },
          quantity: 3,
          price_tier: "bundle3"
        }
      }
    end
  end

  test "should update draw total revenue after purchase" do
    @draw.update!(total_revenue_cents: 0)
    
    post ticket_purchases_url, params: {
      draw_id: @draw.id,
      ticket_purchase: {
        ticket_purchaser_attributes: {
          first_name: "Bob",
          last_name: "Johnson",
          email: "bob@example.com",
          phone: "555-9999"
        },
        quantity: 1,
        price_tier: "single"
      }
    }

    @draw.reload
    assert_equal 500, @draw.total_revenue_cents # Assuming $5 single ticket
  end

  test "should show confirmation page with ticket numbers" do
    ticket = tickets(:one)
    get confirmation_ticket_purchase_url(ticket)
    assert_response :success
    assert_select "h1", "Purchase Confirmation"
    assert_select ".ticket-number", ticket.ticket_number
  end
end