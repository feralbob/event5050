module Admin
  class DrawsController < Admin::ApplicationController
    # Custom action to close a draw
    def close_draw
      draw = Draw.find(params[:id])
      service = DrawClosingService.new(draw)
      result = service.call

      if result.success?
        flash[:notice] = "Draw has been closed successfully."
      else
        flash[:error] = result.error
      end

      redirect_to admin_draw_path(draw)
    end

    # Custom action to select winners
    def select_winners
      draw = Draw.find(params[:id])

      if draw.closed?
        # Select main prize winner
        service = WinnerSelectionService.new(draw)
        result = service.select_winner("main_prize")

        if result.success?
          # Send notification
          notification_service = WinnerNotificationService.new(result.winner)
          notification_service.call

          # Mark draw as drawn
          service.finalize_draw!

          flash[:notice] = "Winner selected successfully! Ticket #{result.winner.ticket_number} won the main prize."
        else
          flash[:error] = result.error
        end
      else
        flash[:error] = "Draw must be closed before selecting winners."
      end

      redirect_to admin_draw_path(draw)
    end
  end
end
