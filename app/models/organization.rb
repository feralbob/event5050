class Organization < ApplicationRecord
  has_many :org_users, dependent: :destroy
  has_many :licenses, dependent: :destroy
  has_many :raffles, dependent: :destroy

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :currency, presence: true
  validate :validate_currency_code

  # Default currency
  attribute :currency, :string, default: "USD"

  # Override setter to ensure nil defaults to USD
  def currency=(value)
    super(value.presence || "USD")
  end

  private

  def validate_currency_code
    return if currency.blank?

    Money::Currency.new(currency)
  rescue Money::Currency::UnknownCurrency
    errors.add(:currency, "is not a valid ISO 4217 currency code")
  end
end
