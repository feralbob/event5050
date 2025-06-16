class Raffle < ApplicationRecord
  belongs_to :organization
  belongs_to :license
  has_many :draws, dependent: :destroy
  has_many :pricing_tiers, dependent: :destroy

  acts_as_tenant(:organization)

  validates :name, presence: true
  validates :currency, presence: true
  validate :validate_currency_code

  # Enums
  enum :status, { draft: 0, active: 1, inactive: 2 }, default: :draft

  # Default values
  attribute :recurring, :boolean, default: false


  def currency
    super || organization&.currency
  end

  private

  def validate_currency_code
    return if currency.blank?

    Money::Currency.new(currency)
  rescue Money::Currency::UnknownCurrency
    errors.add(:currency, "is not a valid ISO 4217 currency code")
  end
end
