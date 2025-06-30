class Customer < ApplicationRecord
  include Customer::Authenticatable
  include Customer::WebauthnAuthenticatable

  has_many :tickets, dependent: :restrict_with_error
  has_many :ticket_purchases, dependent: :restrict_with_error

  validates :first_name, presence: true
  validates :last_name, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
