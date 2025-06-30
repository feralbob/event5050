require "webauthn"

# Configure WebAuthn
Rails.application.config.webauthn_origin = ENV.fetch("WEBAUTHN_ORIGIN") do
  if Rails.env.production?
    "https://#{ENV.fetch('APP_DOMAIN', 'event5050.com')}"
  elsif Rails.env.development?
    "https://#{ENV.fetch('RAILS_DEVELOPMENT_HOSTS', 'event5050.test')}"
  else
    "http://localhost:3000"
  end
end

Rails.application.config.webauthn_rp_name = ENV.fetch("WEBAUTHN_RP_NAME", "Event5050")
Rails.application.config.webauthn_rp_id = ENV.fetch("WEBAUTHN_RP_ID") do
  if Rails.env.production?
    ENV.fetch("APP_DOMAIN", "event5050.com")
  elsif Rails.env.development?
    ENV.fetch("RAILS_DEVELOPMENT_HOSTS", "event5050.test")
  else
    "localhost"
  end
end

# Initialize WebAuthn configuration
WebauthnService.configuration if defined?(WebauthnService)
