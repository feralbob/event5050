require "test_helper"

class LicenseTest < ActiveSupport::TestCase
  setup do
    @jurisdiction = jurisdictions(:one)
  end

  test "should belong to an organization" do
    license = License.new(
      jurisdiction: @jurisdiction,
      license_number: "LIC123",
      issued_at: Date.today,
      expires_at: Date.today + 1.year
    )
    assert_not license.valid?
    assert_includes license.errors[:organization], "must exist"
  end

  test "should belong to a jurisdiction" do
    organization = organizations(:one)
    license = License.new(
      organization: organization,
      license_number: "LIC123",
      issued_at: Date.today,
      expires_at: Date.today + 1.year
    )
    assert_not license.valid?
    assert_includes license.errors[:jurisdiction], "must exist"
  end

  test "should have a license number" do
    license = License.new
    assert_not license.valid?
    assert_includes license.errors[:license_number], "can't be blank"
  end

  test "should have unique license number" do
    organization = organizations(:one)
    License.create!(
      organization: organization,
      jurisdiction: @jurisdiction,
      license_number: "LIC123",
      issued_at: Date.today,
      expires_at: Date.today + 1.year
    )

    duplicate_license = License.new(
      organization: organization,
      jurisdiction: @jurisdiction,
      license_number: "LIC123",
      issued_at: Date.today,
      expires_at: Date.today + 1.year
    )

    assert_not duplicate_license.valid?
    assert_includes duplicate_license.errors[:license_number], "has already been taken"
  end

  test "should have issued_at date" do
    license = License.new(
      organization: organizations(:one),
      jurisdiction: @jurisdiction,
      license_number: "LIC123",
      expires_at: Date.today + 1.year
    )
    assert_not license.valid?
    assert_includes license.errors[:issued_at], "can't be blank"
  end

  test "should have expires_at date" do
    license = License.new(
      organization: organizations(:one),
      jurisdiction: @jurisdiction,
      license_number: "LIC123",
      issued_at: Date.today
    )
    assert_not license.valid?
    assert_includes license.errors[:expires_at], "can't be blank"
  end

  test "expires_at should be after issued_at" do
    license = License.new(
      organization: organizations(:one),
      jurisdiction: @jurisdiction,
      license_number: "LIC123",
      issued_at: Date.today,
      expires_at: Date.today - 1.day
    )
    assert_not license.valid?
    assert_includes license.errors[:expires_at], "must be after issued date"
  end

  test "should handle recurring license type" do
    license = License.new(
      organization: organizations(:one),
      jurisdiction: @jurisdiction,
      license_number: "LIC123",
      issued_at: Date.today,
      expires_at: Date.today + 1.year,
      license_type: "recurring",
      recurrence_rule: "FREQ=WEEKLY;BYDAY=FR"
    )
    assert license.valid?
    assert_equal "recurring", license.license_type
  end

  test "should handle single license type" do
    license = License.new(
      organization: organizations(:one),
      jurisdiction: @jurisdiction,
      license_number: "LIC123",
      issued_at: Date.today,
      expires_at: Date.today + 1.year,
      license_type: "single",
      event_date: Date.today + 1.month
    )
    assert license.valid?
    assert_equal "single", license.license_type
  end

  test "should store requirements as JSON" do
    requirements = {
      "minimum_age" => 19,
      "geographic_restriction" => true,
      "license_fee_percentage" => 2.35
    }

    license = License.create!(
      organization: organizations(:one),
      jurisdiction: @jurisdiction,
      license_number: "LIC123",
      issued_at: Date.today,
      expires_at: Date.today + 1.year,
      requirements: requirements
    )

    license.reload
    assert_equal 19, license.requirements["minimum_age"]
    assert_equal true, license.requirements["geographic_restriction"]
    assert_equal 2.35, license.requirements["license_fee_percentage"]
  end

  test "should know if it's active" do
    # Active license
    active_license = License.create!(
      organization: organizations(:one),
      jurisdiction: @jurisdiction,
      license_number: "ACTIVE123",
      issued_at: Date.today - 1.month,
      expires_at: Date.today + 1.month
    )
    assert active_license.active?

    # Expired license
    expired_license = License.create!(
      organization: organizations(:one),
      jurisdiction: @jurisdiction,
      license_number: "EXPIRED123",
      issued_at: Date.today - 2.months,
      expires_at: Date.today - 1.day
    )
    assert_not expired_license.active?

    # Not yet active license
    future_license = License.create!(
      organization: organizations(:one),
      jurisdiction: @jurisdiction,
      license_number: "FUTURE123",
      issued_at: Date.today + 1.day,
      expires_at: Date.today + 1.year
    )
    assert_not future_license.active?
  end
end
