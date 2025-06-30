module Customer::WebauthnAuthenticatable
  extend ActiveSupport::Concern

  included do
    validates :webauthn_id, presence: true, uniqueness: true
  end

  def add_webauthn_credential(webauthn_credential, nickname: nil)
    webauthn_credentials.create!(
      external_id: webauthn_credential.id,
      public_key: Base64.strict_encode64(webauthn_credential.public_key),
      sign_count: webauthn_credential.sign_count,
      nickname: nickname || default_credential_nickname
    )
  end

  def update_credential_after_authentication(webauthn_credential)
    credential = webauthn_credentials.find_by!(external_id: webauthn_credential.id)

    credential.update!(
      sign_count: webauthn_credential.sign_count,
      last_used_at: Time.current
    )
  end

  def can_delete_credential?(credential)
    # Ensure at least one credential remains
    webauthn_credentials.count > 1
  end

  def webauthn_enabled?
    webauthn_credentials.exists?
  end

  def credentials_for_get
    webauthn_credentials.pluck(:external_id)
  end

  private

  def default_credential_nickname
    device_names = [
      "Security Key",
      "Touch ID",
      "Face ID",
      "Windows Hello",
      "Fingerprint"
    ]

    existing_nicknames = webauthn_credentials.pluck(:nickname)

    device_names.each do |name|
      next if existing_nicknames.include?(name)
      return name
    end

    "Security Key ##{webauthn_credentials.count + 1}"
  end
end
