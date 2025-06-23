class TicketPurchasesController < ApplicationController
  before_action :set_draw, only: [ :show, :create ]

  def index
    @draws = Draw.active_for_purchase.includes(:raffle)
  end

  def show
    @ticket_purchase_form = TicketPurchaseForm.new
    @pricing_tiers = @draw.raffle.pricing_tiers.active.ordered
  end

  def create
    @ticket_purchase_form = TicketPurchaseForm.new(ticket_purchase_params)

    if @ticket_purchase_form.valid?
      pricing_tier = @draw.raffle.pricing_tiers.find_by(id: params[:ticket_purchase][:pricing_tier_id])

      unless pricing_tier
        @ticket_purchase_form.errors.add(:base, "Please select a valid ticket option")
        @pricing_tiers = @draw.raffle.pricing_tiers.active.ordered
        render :show and return
      end

      service = TicketPurchaseService.new(
        draw: @draw,
        pricing_tier: pricing_tier,
        purchaser_attributes: params[:ticket_purchase][:customer_attributes].permit(
          :first_name, :last_name, :email, :phone
        )
      )

      result = service.purchase!

      if result.success?
        redirect_to confirmation_ticket_purchase_path(result.tickets.first)
      else
        @ticket_purchase_form.errors.add(:base, result.error)
        @pricing_tiers = @draw.raffle.pricing_tiers.active.ordered
        render :show
      end
    else
      @pricing_tiers = @draw.raffle.pricing_tiers.active.ordered
      render :show
    end
  end

  def confirmation
    @ticket = Ticket.find(params[:id])
    @all_tickets = Ticket.where(
      customer: @ticket.customer,
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
      :pricing_tier_id,
      customer_attributes: [ :first_name, :last_name, :email, :phone ]
    )
  end
end

class TicketPurchaseForm
  include ActiveModel::Model

  attr_accessor :pricing_tier_id, :customer_attributes

  validates :pricing_tier_id, presence: true
  validate :customer_attributes_valid

  private

  def customer_attributes_valid
    return unless customer_attributes

    if customer_attributes[:email].blank?
      errors.add(:base, "Email is required")
    end

    if customer_attributes[:first_name].blank?
      errors.add(:base, "First name is required")
    end

    if customer_attributes[:last_name].blank?
      errors.add(:base, "Last name is required")
    end
  end
end
