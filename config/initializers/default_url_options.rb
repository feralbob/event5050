# Set default URL options for all environments
# This ensures consistent URL generation across the application

Rails.application.configure do
  if Rails.env.production?
    # Force HTTPS for all URL helpers in production
    Rails.application.routes.default_url_options[:protocol] = "https"

    # Also set the host if APP_DOMAIN is configured
    if ENV["APP_DOMAIN"].present?
      Rails.application.routes.default_url_options[:host] = ENV["APP_DOMAIN"]
    end
  elsif Rails.env.development?
    # Use puma-dev for development (HTTPS)
    Rails.application.routes.default_url_options[:host] = ENV.fetch("RAILS_DEVELOPMENT_HOSTS", "event5050.test")
    Rails.application.routes.default_url_options[:protocol] = "https"
  elsif Rails.env.test?
    # Use example.com for tests
    Rails.application.routes.default_url_options[:host] = "example.com"
    Rails.application.routes.default_url_options[:protocol] = "https"
  end
end
