class CustomerMailer < ApplicationMailer
  def confirmation_instructions(customer)
    @customer = customer
    @confirmation_url = customers_confirmations_url(@customer.confirmation_token)

    mail(
      to: @customer.email,
      subject: "Confirm your Event5050 account"
    )
  end
end
