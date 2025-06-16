class Draw < ApplicationRecord
  belongs_to :raffle
  has_many :tickets, dependent: :restrict_with_error
  has_many :ticket_purchases, dependent: :restrict_with_error

  # Money gem integration
  monetize :total_revenue_cents, with_model_currency: :currency, allow_nil: true

  validates :draw_date, presence: true
  validates :ticket_sales_start_at, presence: true
  validates :ticket_sales_end_at, presence: true
  validate :validate_date_sequence

  # Enums
  enum :status, { scheduled: 0, active: 1, closed: 2, drawn: 3 }, default: :scheduled

  # Default values
  attribute :total_revenue_cents, :integer, default: 0
  attribute :prize_pool, :jsonb, default: {}

  def currency
    super || raffle&.currency
  end


  def formatted_total_revenue
    total_revenue&.format || "$0.00"
  end

  def ticket_sales_open?
    return false unless ticket_sales_start_at && ticket_sales_end_at
    current_time = Time.current
    current_time >= ticket_sales_start_at && current_time <= ticket_sales_end_at && active?
  end

  # Scopes
  scope :active_for_purchase, -> {
    where(status: :active)
      .where("ticket_sales_start_at <= ?", Time.current)
      .where("ticket_sales_end_at >= ?", Time.current)
  }

  # Calculate prize pool based on total revenue (legacy method)
  def calculate_prize_pool!
    return if total_revenue_cents.nil? || total_revenue_cents == 0

    main_prize = (total_revenue_cents / 2) # 50% for main prize
    organization_revenue = total_revenue_cents - main_prize

    self.prize_pool = {
      "main_prize_cents" => main_prize,
      "organization_revenue_cents" => organization_revenue
    }
    save!
  end

  # Enhanced prize pool calculation using Money gem and fee services
  def calculate_prize_pool_with_services!(license_requirements: {})
    return if total_revenue.nil? || total_revenue.zero?

    distributor = PrizePoolDistributor.new(self, total_revenue, license_requirements: license_requirements)
    distribution = distributor.calculate_distribution

    self.prize_pool = {
      "main_prize_cents" => distribution[:main_prize].cents,
      "platform_fee_cents" => distribution[:platform_fee].cents,
      "license_fee_cents" => distribution[:license_fee].cents,
      "organization_share_cents" => distribution[:organization_share].cents,
      "currency" => total_revenue.currency.to_s,
      "calculated_at" => Time.current.iso8601,
      "secondary_prizes" => distribution[:secondary_prizes]
    }
    save!
  end

  # Enhanced prize pool calculation with Money objects
  def calculate_prize_pool_with_fees!
    return if total_revenue.nil? || total_revenue.zero?

    # TODO: Integrate with FeeCalculator service
    # For now, use simple 50/50 split
    main_prize = total_revenue / 2
    organization_revenue = total_revenue - main_prize

    self.prize_pool = {
      "main_prize_cents" => main_prize.cents,
      "organization_revenue_cents" => organization_revenue.cents,
      "currency" => currency
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

  # Increment revenue when ticket is purchased - support both integers and Money objects
  def increment_revenue!(amount)
    if amount.is_a?(Money)
      increment!(:total_revenue_cents, amount.cents)
    else
      increment!(:total_revenue_cents, amount)
    end
  end

  # Calculate revenue from ticket purchases for accuracy
  def calculate_revenue_from_purchases!
    purchase_total = ticket_purchases.sum(:total_amount_cents)
    update!(total_revenue_cents: purchase_total)
  end

  # Get revenue as Money object, with fallback to calculated value
  def total_revenue
    if total_revenue_cents.present?
      Money.new(total_revenue_cents, currency)
    else
      # Calculate from ticket purchases if revenue not cached
      purchase_total_cents = ticket_purchases.sum(:total_amount_cents)
      Money.new(purchase_total_cents, currency)
    end
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
