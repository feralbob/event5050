require "test_helper"

class Admin::PricingTiersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = organizations(:one)
    @raffle = raffles(:one)
    @pricing_tier = pricing_tiers(:single)

    ActsAsTenant.current_tenant = nil # Admin operates without tenant restrictions
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "should get index" do
    get admin_pricing_tiers_url
    assert_response :success
    assert_select "h1", "Pricing Tiers"
  end

  test "should show pricing tier" do
    get admin_pricing_tier_url(@pricing_tier)
    assert_response :success
    assert_select "h1", /#{@pricing_tier.name}/
  end

  test "should get new" do
    get new_admin_pricing_tier_url
    assert_response :success
    assert_select "h1", "New Pricing Tier"
  end

  test "should create pricing tier" do
    assert_difference("PricingTier.count") do
      post admin_pricing_tiers_url, params: {
        pricing_tier: {
          raffle_id: @raffle.id,
          name: "Test Tier",
          code: "test_tier",
          ticket_quantity: 5,
          total_price_cents: 2000,
          display_order: 10,
          active: true,
          description: "Test description"
        }
      }
    end

    assert_redirected_to admin_pricing_tier_url(PricingTier.last)
  end

  test "should get edit" do
    get edit_admin_pricing_tier_url(@pricing_tier)
    assert_response :success
    assert_select "h1", /Edit/
  end

  test "should update pricing tier" do
    patch admin_pricing_tier_url(@pricing_tier), params: {
      pricing_tier: {
        name: "Updated Name",
        description: "Updated description"
      }
    }

    assert_redirected_to admin_pricing_tier_url(@pricing_tier)

    @pricing_tier.reload
    assert_equal "Updated Name", @pricing_tier.name
    assert_equal "Updated description", @pricing_tier.description
  end

  test "should toggle active status" do
    original_status = @pricing_tier.active

    patch toggle_active_admin_pricing_tier_url(@pricing_tier)

    assert_redirected_to admin_pricing_tier_url(@pricing_tier)

    @pricing_tier.reload
    assert_equal !original_status, @pricing_tier.active
  end

  test "should duplicate pricing tier" do
    original_count = PricingTier.count

    post duplicate_admin_pricing_tier_url(@pricing_tier)

    assert_equal original_count + 1, PricingTier.count
    assert_redirected_to admin_pricing_tier_url(PricingTier.last)

    duplicated_tier = PricingTier.last
    assert_equal "#{@pricing_tier.name} (Copy)", duplicated_tier.name
    assert_includes duplicated_tier.code, "copy"
    assert_equal @pricing_tier.raffle_id, duplicated_tier.raffle_id
    assert_equal @pricing_tier.ticket_quantity, duplicated_tier.ticket_quantity
    assert_equal @pricing_tier.total_price_cents, duplicated_tier.total_price_cents
  end

  test "should destroy pricing tier" do
    assert_difference("PricingTier.count", -1) do
      delete admin_pricing_tier_url(@pricing_tier)
    end

    assert_redirected_to admin_pricing_tiers_url
  end

  test "should validate required fields" do
    post admin_pricing_tiers_url, params: {
      pricing_tier: {
        name: "",
        code: "",
        ticket_quantity: 0,
        total_price_cents: 0
      }
    }

    assert_response :unprocessable_entity
    assert_select ".field_with_errors"
  end

  test "should enforce unique code per raffle" do
    existing_tier = @pricing_tier

    post admin_pricing_tiers_url, params: {
      pricing_tier: {
        raffle_id: existing_tier.raffle_id,
        name: "Different Name",
        code: existing_tier.code, # Same code
        ticket_quantity: 1,
        total_price_cents: 500
      }
    }

    assert_response :unprocessable_entity
    assert_select ".field_with_errors"
  end

  test "should filter by active status" do
    get admin_pricing_tiers_url(search: "active:")
    assert_response :success

    get admin_pricing_tiers_url(search: "inactive:")
    assert_response :success
  end

  test "should order by display_order by default" do
    # Create pricing tiers with different display orders
    tier1 = PricingTier.create!(
      raffle: @raffle,
      name: "First",
      code: "first_#{Time.current.to_i}",
      ticket_quantity: 1,
      total_price_cents: 500,
      display_order: 1
    )

    tier2 = PricingTier.create!(
      raffle: @raffle,
      name: "Second",
      code: "second_#{Time.current.to_i}",
      ticket_quantity: 1,
      total_price_cents: 500,
      display_order: 2
    )

    get admin_pricing_tiers_url
    assert_response :success

    # The response should contain pricing tiers in display order
    response_body = response.body
    first_pos = response_body.index(tier1.name)
    second_pos = response_body.index(tier2.name)

    assert first_pos < second_pos, "Pricing tiers should be ordered by display_order"
  end
end
