ActsAsTenant.configure do |config|
  # By default, ActsAsTenant adds a NOT NULL constraint to the tenant_id.
  # We want to allow nil tenant_id for the initial onboarding flow.
  config.require_tenant = false
end