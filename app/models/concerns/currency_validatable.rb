module CurrencyValidatable
  extend ActiveSupport::Concern

  included do
    validate :validate_currency_code
  end

  private

  def validate_currency_code
    return if currency.blank?

    Money::Currency.new(currency)
  rescue Money::Currency::UnknownCurrency
    errors.add(:currency, "is not a valid ISO 4217 currency code")
  end
end