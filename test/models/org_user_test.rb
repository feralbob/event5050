require "test_helper"

class OrgUserTest < ActiveSupport::TestCase
  test "should have a valid factory" do
    organization = Organization.create(name: "Test Org", description: "Test")
    org_user = OrgUser.new(
      email: "test@example.com",
      password: "password123",
      first_name: "Test",
      last_name: "User",
      organization: organization,
      role: "admin"
    )
    assert org_user.valid?
  end

  test "should require an email" do
    org_user = OrgUser.new(password: "password123")
    assert_not org_user.valid?
    assert_includes org_user.errors[:email], "can't be blank"
  end

  test "should require a valid email format" do
    org_user = OrgUser.new(email: "invalid-email", password: "password123")
    assert_not org_user.valid?
    assert_includes org_user.errors[:email], "is invalid"
  end

  test "should belong to an organization" do
    org_user = OrgUser.new
    assert_respond_to org_user, :organization
  end

  test "should have a role enum" do
    org_user = OrgUser.new
    assert_respond_to org_user, :admin?
    assert_respond_to org_user, :finance?
    assert_respond_to org_user, :legal?
    assert_respond_to org_user, :support?
  end

  test "should default to admin role" do
    org_user = OrgUser.new
    assert_equal "admin", org_user.role
  end

  test "should require first_name and last_name" do
    org_user = OrgUser.new(email: "test@example.com", password: "password123")
    assert_not org_user.valid?
    assert_includes org_user.errors[:first_name], "can't be blank"
    assert_includes org_user.errors[:last_name], "can't be blank"
  end

  test "should be scoped by organization using acts_as_tenant" do
    skip "Will test after acts_as_tenant is configured"
  end
end
