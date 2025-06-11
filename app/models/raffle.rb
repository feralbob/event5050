class Raffle < ApplicationRecord
  belongs_to :organization
  belongs_to :license
  has_many :draws, dependent: :destroy
  
  acts_as_tenant(:organization)
  
  validates :name, presence: true
  
  # Default values
  attribute :status, :string, default: 'draft'
  attribute :recurring, :boolean, default: false
  attribute :ticket_pricing, :jsonb, default: []
end
