require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "should have a valid factory" do
    organization = Organization.new(
      name: "Test Organization",
      description: "A test organization"
    )
    assert organization.valid?
  end

  test "should require a name" do
    organization = Organization.new(description: "Test description")
    assert_not organization.valid?
    assert_includes organization.errors[:name], "can't be blank"
  end

  test "should have many org_users" do
    assert_respond_to Organization.new, :org_users
  end

  test "should destroy associated org_users when destroyed" do
    skip "Will implement after OrgUser model is created"
  end

  test "name should have reasonable length" do
    organization = Organization.new(name: "a" * 256, description: "Test")
    assert_not organization.valid?
    assert_includes organization.errors[:name], "is too long (maximum is 255 characters)"
  end
end