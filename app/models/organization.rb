class Organization < ApplicationRecord
  include CurrencyValidatable
  
  has_many :org_users, dependent: :destroy
  has_many :licenses, dependent: :destroy
  has_many :raffles, dependent: :destroy

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :currency, presence: true
end
