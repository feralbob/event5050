class DrawClosingService
  Result = Struct.new(:success?, :error, :draw, keyword_init: true)
  
  def initialize(draw)
    @draw = draw
  end
  
  def call
    return Result.new(success?: false, error: "Draw is already closed") if @draw.closed? || @draw.drawn?
    return Result.new(success?: false, error: "Sales period has not ended") if @draw.ticket_sales_end_at > Time.current
    
    ActiveRecord::Base.transaction do
      @draw.closed!
      @draw.calculate_prize_pool!
    end
    
    Result.new(success?: true, draw: @draw)
  rescue => e
    Result.new(success?: false, error: e.message)
  end
end