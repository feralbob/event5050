require "test_helper"

class WinnerNotificationServiceTest < ActiveSupport::TestCase
  setup do
    @ticket = tickets(:one)
    @ticket.update!(status: :won, prize_won: "main_prize")
    @draw = @ticket.draw
    @draw.update!(
      status: :drawn,
      prize_pool: {
        "main_prize_cents" => 5000,
        "organization_revenue_cents" => 5000
      }
    )
    @service = WinnerNotificationService.new(@ticket)
  end

  test "should send notification to winner" do
    result = @service.call

    assert result.success?
    assert_equal "Notification sent successfully", result.message
  end

  test "should include ticket number in notification" do
    notification_data = @service.build_notification_data

    assert_equal @ticket.ticket_number, notification_data[:ticket_number]
  end

  test "should include prize amount in notification" do
    notification_data = @service.build_notification_data

    assert_equal 5000, notification_data[:prize_amount_cents]
    assert_equal "$50.00", notification_data[:prize_amount_formatted]
  end

  test "should include winner details" do
    notification_data = @service.build_notification_data

    assert_equal @ticket.ticket_purchaser.full_name, notification_data[:winner_name]
    assert_equal @ticket.ticket_purchaser.email, notification_data[:winner_email]
  end

  test "should include draw details" do
    notification_data = @service.build_notification_data

    assert_equal @draw.raffle.name, notification_data[:raffle_name]
    assert_equal @draw.draw_date, notification_data[:draw_date]
  end

  test "should not send notification for non-winning ticket" do
    @ticket.update!(status: :active, prize_won: nil)

    result = @service.call

    assert_not result.success?
    assert_equal "Ticket has not won a prize", result.error
  end

  test "should handle main prize notification" do
    @ticket.update!(prize_won: "main_prize")

    notification_data = @service.build_notification_data

    assert_equal "Main Prize Winner", notification_data[:prize_type]
    assert_equal 5000, notification_data[:prize_amount_cents]
  end

  test "should handle secondary prize notification" do
    @ticket.update!(prize_won: "early_bird")
    @draw.update!(prize_pool: @draw.prize_pool.merge({
      "secondary_prizes" => [
        { "name" => "early_bird", "amount_cents" => 1000 }
      ]
    }))

    notification_data = @service.build_notification_data

    assert_equal "Early Bird Prize Winner", notification_data[:prize_type]
    assert_equal 1000, notification_data[:prize_amount_cents]
  end
end
