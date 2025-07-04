class CustomerMailer < ApplicationMailer
  def confirmation_instructions(customer)
    @customer = customer
    @confirmation_url = customers_confirm_email_url(@customer.confirmation_token)

    mail(
      to: @customer.email,
      subject: "Confirm your Event5050 account"
    )
  end

  def verification_reminder(customer)
    @customer = customer
    @confirmation_url = customers_confirm_email_url(@customer.confirmation_token)

    mail(
      to: @customer.email,
      subject: "Reminder: Please verify your Event5050 account"
    )
  end

  def final_verification_reminder(customer)
    @customer = customer
    @confirmation_url = customers_confirm_email_url(@customer.confirmation_token)

    mail(
      to: @customer.email,
      subject: "Final reminder: Verify your Event5050 account"
    )
  end
end
