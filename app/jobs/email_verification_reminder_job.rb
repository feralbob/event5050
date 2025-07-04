class EmailVerificationReminderJob < ApplicationJob
  queue_as :default

  def perform
    # Find unconfirmed customers who registered 3 days ago
    Customer.unconfirmed
            .where(created_at: 3.days.ago.beginning_of_day..3.days.ago.end_of_day)
            .find_each do |customer|
      CustomerMailer.verification_reminder(customer).deliver_later
    end

    # Find unconfirmed customers who registered 7 days ago
    Customer.unconfirmed
            .where(created_at: 7.days.ago.beginning_of_day..7.days.ago.end_of_day)
            .find_each do |customer|
      CustomerMailer.final_verification_reminder(customer).deliver_later
    end
  end
end