class WinnerNotificationService
  Result = Struct.new(:success?, :error, :message, keyword_init: true)

  def initialize(ticket)
    @ticket = ticket
    @draw = ticket.draw
  end

  def call
    return Result.new(success?: false, error: "Ticket has not won a prize") unless @ticket.won?

    # In the MVP, we'll just return success
    # In production, this would send an email/SMS
    Result.new(
      success?: true,
      message: "Notification sent successfully"
    )
  end

  def build_notification_data
    prize_amount = calculate_prize_amount

    {
      ticket_number: @ticket.ticket_number,
      winner_name: @ticket.customer.full_name,
      winner_email: @ticket.customer.email,
      raffle_name: @draw.raffle.name,
      draw_date: @draw.draw_date,
      prize_type: format_prize_type,
      prize_amount_cents: prize_amount,
      prize_amount_formatted: format_currency(prize_amount)
    }
  end

  private

  def calculate_prize_amount
    return 0 unless @ticket.prize_won

    if @ticket.prize_won == "main_prize"
      @draw.prize_pool["main_prize_cents"] || 0
    else
      # Look for secondary prizes
      secondary_prizes = @draw.prize_pool["secondary_prizes"] || []
      prize = secondary_prizes.find { |p| p["name"] == @ticket.prize_won }
      prize ? prize["amount_cents"] : 0
    end
  end

  def format_prize_type
    case @ticket.prize_won
    when "main_prize"
      "Main Prize Winner"
    when "early_bird"
      "Early Bird Prize Winner"
    else
      "#{@ticket.prize_won.humanize} Winner"
    end
  end

  def format_currency(cents)
    Money.new(cents, "USD").format
  end
end
