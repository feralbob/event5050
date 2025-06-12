module Admin
  class PricingTiersController < Admin::ApplicationController
    # Overwrite any of the RESTful controller actions to implement custom behavior
    # For example, you may want to send an email after a foo is updated.
    #
    # def update
    #   super
    #   send_foo_updated_email(requested_resource)
    # end

    # Override the default scope to include associated data
    def scoped_resource
      resource_class.includes(:raffle, :tickets)
    end

    # Custom action to duplicate a pricing tier
    def duplicate
      original_tier = requested_resource
      new_tier = original_tier.dup
      new_tier.name = "#{original_tier.name} (Copy)"
      new_tier.code = "#{original_tier.code}_copy_#{Time.current.to_i}"

      if new_tier.save
        redirect_to admin_pricing_tier_path(new_tier), notice: "Pricing tier duplicated successfully"
      else
        redirect_to admin_pricing_tier_path(original_tier), alert: "Failed to duplicate pricing tier"
      end
    end

    # Custom action to toggle active status
    def toggle_active
      pricing_tier = requested_resource
      pricing_tier.update!(active: !pricing_tier.active)

      status = pricing_tier.active? ? "activated" : "deactivated"
      redirect_to admin_pricing_tier_path(pricing_tier), notice: "Pricing tier #{status} successfully"
    end

    private

    # Override the default ordering
    def order
      @order ||= Administrate::Order.new(
        params.fetch(resource_name, {}).fetch(:order, "display_order"),
        params.fetch(resource_name, {}).fetch(:direction, "asc")
      )
    end
  end
end
