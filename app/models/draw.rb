class Draw < ApplicationRecord
  belongs_to :raffle
  has_many :tickets, dependent: :restrict_with_error
  
  validates :draw_date, presence: true
  validates :ticket_sales_start_at, presence: true
  validates :ticket_sales_end_at, presence: true
  validate :validate_date_sequence
  
  # Default values
  attribute :status, :string, default: 'scheduled'
  attribute :total_revenue_cents, :integer, default: 0
  attribute :prize_pool, :jsonb, default: {}
  
  def ticket_sales_open?
    return false unless ticket_sales_start_at && ticket_sales_end_at
    current_time = Time.current
    current_time >= ticket_sales_start_at && current_time <= ticket_sales_end_at && status == 'active'
  end
  
  private
  
  def validate_date_sequence
    if ticket_sales_start_at && ticket_sales_end_at
      if ticket_sales_end_at <= ticket_sales_start_at
        errors.add(:ticket_sales_end_at, "must be after start time")
      end
    end
    
    if draw_date && ticket_sales_end_at
      if draw_date < ticket_sales_end_at.to_date
        errors.add(:draw_date, "must be on or after ticket sales end")
      end
    end
  end
end
