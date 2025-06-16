class TicketPurchase < ApplicationRecord
  include CurrencyValidatable
  include CurrencyConsistencyValidatable

  belongs_to :draw
  belongs_to :ticket_purchaser
  belongs_to :pricing_tier
  has_many :tickets, dependent: :nullify

  # Money gem integration
  monetize :total_amount_cents, with_model_currency: :currency, allow_nil: false

  validates :total_amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :total_amount, presence: true, money: { greater_than: 0 }
  validates :currency, presence: true
  validates :purchase_date, presence: true

  # Default values
  attribute :metadata, :jsonb, default: -> { {} }
  attribute :purchase_date, :datetime, default: -> { Time.current }

  # Default currency - inherit from pricing tier if available
  def currency
    read_attribute(:currency) || pricing_tier&.currency || "USD"
  end

  def formatted_amount
    total_amount.format
  end

  def ticket_count
    pricing_tier.ticket_quantity
  end

  private

  def validate_currency_consistency
    return unless pricing_tier.present? && currency.present?
    
    if currency != pricing_tier.currency
      errors.add(:currency, "must match pricing tier currency (#{pricing_tier.currency})")
    end
  end
end
