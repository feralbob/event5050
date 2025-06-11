class TicketPurchasesController < ApplicationController
  before_action :set_draw, only: [:show, :create]
  
  def index
    @draws = Draw.active_for_purchase.includes(:raffle)
  end
  
  def show
    @ticket_purchase = TicketPurchase.new
  end
  
  def create
    @ticket_purchase = TicketPurchase.new(ticket_purchase_params)
    
    if @ticket_purchase.valid?
      ActiveRecord::Base.transaction do
        # Find or create ticket purchaser
        ticket_purchaser = find_or_create_ticket_purchaser
        
        # Create tickets based on quantity
        tickets = []
        quantity = params[:ticket_purchase][:quantity].to_i
        price_tier = params[:ticket_purchase][:price_tier]
        price_cents = calculate_price_cents(price_tier)
        
        quantity.times do
          ticket = @draw.tickets.build(
            ticket_purchaser: ticket_purchaser,
            price_cents: price_cents,
            status: :active
          )
          ticket.generate_ticket_number!
          ticket.save!
          tickets << ticket
        end
        
        # Update draw revenue
        total_amount = price_cents * quantity
        @draw.increment_revenue!(total_amount)
        
        # Redirect to confirmation for the first ticket
        redirect_to confirmation_ticket_purchase_path(tickets.first)
      end
    else
      render :show
    end
  end
  
  def confirmation
    @ticket = Ticket.find(params[:id])
    @all_tickets = Ticket.where(
      ticket_purchaser: @ticket.ticket_purchaser,
      draw: @ticket.draw,
      created_at: (@ticket.created_at - 1.minute)..(@ticket.created_at + 1.minute)
    )
  end
  
  private
  
  def set_draw
    @draw = Draw.find(params[:draw_id] || params[:id])
  end
  
  def ticket_purchase_params
    params.require(:ticket_purchase).permit(
      :quantity, 
      :price_tier,
      ticket_purchaser_attributes: [:first_name, :last_name, :email, :phone]
    )
  end
  
  def find_or_create_ticket_purchaser
    attrs = params[:ticket_purchase][:ticket_purchaser_attributes]
    TicketPurchaser.find_or_create_by(email: attrs[:email]) do |tp|
      tp.first_name = attrs[:first_name]
      tp.last_name = attrs[:last_name]
      tp.phone = attrs[:phone]
    end
  end
  
  def calculate_price_cents(price_tier)
    # For MVP, we'll use hardcoded pricing
    # TODO: Get from raffle.ticket_pricing
    case price_tier
    when "single"
      500 # $5
    when "bundle3"
      1000 # $10 for 3
    else
      500
    end
  end
end

class TicketPurchase
  include ActiveModel::Model
  
  attr_accessor :quantity, :price_tier, :ticket_purchaser_attributes
  
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price_tier, presence: true
end