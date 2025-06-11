class WinnerSelectionService
  Result = Struct.new(:success?, :error, :winner, :message, keyword_init: true)
  
  def initialize(draw)
    @draw = draw
  end
  
  def select_winner(prize_name)
    return Result.new(success?: false, error: "Draw must be closed before selecting winners") unless @draw.closed?
    
    # Get eligible tickets (active status, not already won, unique purchasers)
    won_purchaser_ids = @draw.tickets.won.pluck(:ticket_purchaser_id)
    eligible_tickets = @draw.tickets
      .active
      .where.not(ticket_purchaser_id: won_purchaser_ids)
      .to_a
    
    return Result.new(success?: false, error: "No eligible tickets available") if eligible_tickets.empty?
    
    # Select random winner
    winning_ticket = eligible_tickets.sample
    
    ActiveRecord::Base.transaction do
      winning_ticket.update!(
        status: :won,
        prize_won: prize_name
      )
    end
    
    Result.new(
      success?: true, 
      winner: winning_ticket,
      message: "Winner selected for #{prize_name}"
    )
  rescue => e
    Result.new(success?: false, error: e.message)
  end
  
  def finalize_draw!
    @draw.drawn! if @draw.closed?
  end
end