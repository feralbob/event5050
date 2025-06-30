module Customer::Authenticatable
  extend ActiveSupport::Concern

  included do
    has_many :webauthn_credentials, dependent: :destroy

    before_validation :generate_webauthn_id, on: :create
    before_validation :downcase_email

    validates :email, presence: true, uniqueness: { case_sensitive: false }
    validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

    scope :confirmed, -> { where.not(email_confirmed_at: nil) }
    scope :unconfirmed, -> { where(email_confirmed_at: nil) }
  end


  def confirmed?
    email_confirmed_at.present?
  end

  def confirm!
    update!(email_confirmed_at: Time.current, confirmation_token: nil)
  end

  def generate_confirmation_token!
    update!(
      confirmation_token: generate_token,
      confirmation_sent_at: Time.current
    )
  end


  def update_sign_in_info(ip_address)
    update!(
      last_sign_in_at: Time.current,
      last_sign_in_ip: ip_address,
      sign_in_count: sign_in_count + 1
    )
  end

  def generate_session_token
    update!(session_token: generate_token)
    session_token
  end

  def clear_session_token!
    update!(session_token: nil)
  end

  private

  def generate_webauthn_id
    self.webauthn_id ||= WebAuthn.generate_user_id
  end

  def downcase_email
    self.email = email&.downcase&.strip
  end

  def generate_token
    SecureRandom.urlsafe_base64(32)
  end
end
