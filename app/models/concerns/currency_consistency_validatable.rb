module CurrencyConsistencyValidatable
  extend ActiveSupport::Concern

  included do
    validate :validate_currency_consistency
  end

  private

  def validate_currency_consistency
    # Override in including class to define specific consistency rules
  end
end