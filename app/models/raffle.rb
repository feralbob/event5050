class Raffle < ApplicationRecord
  belongs_to :organization
  belongs_to :license
  has_many :draws, dependent: :destroy
  has_many :pricing_tiers, dependent: :destroy
  
  acts_as_tenant(:organization)
  
  validates :name, presence: true
  
  # Enums
  enum :status, { draft: 0, active: 1, inactive: 2 }, default: :draft
  
  # Default values
  attribute :recurring, :boolean, default: false
  attribute :ticket_pricing, :jsonb, default: []
end
