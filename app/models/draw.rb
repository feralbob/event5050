class Draw < ApplicationRecord
  belongs_to :raffle
  has_many :tickets, dependent: :restrict_with_error
  
  validates :draw_date, presence: true
  validates :ticket_sales_start_at, presence: true
  validates :ticket_sales_end_at, presence: true
  validate :validate_date_sequence
  
  # Enums
  enum :status, { scheduled: 0, active: 1, closed: 2, drawn: 3 }, default: :scheduled
  
  # Default values
  attribute :total_revenue_cents, :integer, default: 0
  attribute :prize_pool, :jsonb, default: {}
  
  def ticket_sales_open?
    return false unless ticket_sales_start_at && ticket_sales_end_at
    current_time = Time.current
    current_time >= ticket_sales_start_at && current_time <= ticket_sales_end_at && active?
  end
  
  # Scopes
  scope :active_for_purchase, -> { 
    where(status: :active)
      .where('ticket_sales_start_at <= ?', Time.current)
      .where('ticket_sales_end_at >= ?', Time.current)
  }
  
  # Calculate prize pool based on total revenue
  def calculate_prize_pool!
    return if total_revenue_cents.nil? || total_revenue_cents == 0
    
    main_prize = (total_revenue_cents * 0.5).to_i # 50% for main prize
    organization_revenue = total_revenue_cents - main_prize
    
    self.prize_pool = {
      "main_prize_cents" => main_prize,
      "organization_revenue_cents" => organization_revenue
    }
    save!
  end
  
  # Check and update status based on current time
  def check_and_update_status!
    current_time = Time.current
    
    if scheduled? && ticket_sales_start_at <= current_time && ticket_sales_end_at >= current_time
      active!
    elsif active? && ticket_sales_end_at < current_time
      closed!
    end
  end
  
  # Increment revenue when ticket is purchased
  def increment_revenue!(amount_cents)
    increment!(:total_revenue_cents, amount_cents)
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
