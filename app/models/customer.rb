class Customer < ApplicationRecord
  has_many :tickets, dependent: :restrict_with_error
  has_many :ticket_purchases, dependent: :restrict_with_error

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true
  validates :last_name, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
