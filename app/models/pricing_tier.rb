class PricingTier < ApplicationRecord
  belongs_to :raffle
  has_many :tickets, dependent: :nullify
  has_many :ticket_purchases, dependent: :restrict_with_error

  # Money gem integration
  monetize :total_price_cents, with_model_currency: :currency, allow_nil: false

  # Inherit tenant from raffle

  validates :name, presence: true
  validates :code, presence: true, uniqueness: { scope: :raffle_id }
  validates :ticket_quantity, presence: true, numericality: { greater_than: 0 }
  validates :total_price_cents, presence: true, numericality: { greater_than: 0 }
  validates :total_price, presence: true, money: { greater_than: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:display_order, :ticket_quantity) }

  def currency
    super || raffle&.currency
  end


  def price_per_ticket_cents
    total_price_cents / ticket_quantity
  end

  def price_per_ticket
    total_price / ticket_quantity
  end

  def savings_cents(base_tier)
    return 0 unless base_tier

    base_total = base_tier.price_per_ticket_cents * ticket_quantity
    base_total - total_price_cents
  end

  def savings(base_tier)
    return Money.new(0, currency) unless base_tier

    base_total = base_tier.price_per_ticket * ticket_quantity
    base_total - total_price
  end

  def display_text
    "#{name} - #{formatted_price}"
  end

  def display_text_with_description
    return display_text if description.blank?
    "#{display_text} (#{description})"
  end

  def formatted_price
    total_price.format
  end
end
