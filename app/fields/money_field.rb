require "administrate/field/base"

class MoneyField < Administrate::Field::Base
  def to_s
    return "" unless data.present?

    if data.respond_to?(:format)
      # It's already a Money object
      data.format
    elsif resource.respond_to?(:"#{attribute}_currency")
      # We have both cents and currency
      currency = resource.public_send(:"#{attribute}_currency") || "USD"
      Money.new(data, currency).format
    else
      # Fallback to USD
      Money.new(data, "USD").format
    end
  end

  def to_partial_path
    "/fields/money_field/#{page}"
  end
end
