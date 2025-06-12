require "test_helper"

class JurisdictionTest < ActiveSupport::TestCase
  test "should have a name" do
    jurisdiction = Jurisdiction.new
    assert_not jurisdiction.valid?
    assert_includes jurisdiction.errors[:name], "can't be blank"
  end

  test "should have a unique name" do
    jurisdiction1 = Jurisdiction.create!(name: "California", boundary: "POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))")
    jurisdiction2 = Jurisdiction.new(name: "California", boundary: "POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))")

    assert_not jurisdiction2.valid?
    assert_includes jurisdiction2.errors[:name], "has already been taken"
  end

  test "should have a boundary" do
    jurisdiction = Jurisdiction.new(name: "Test State")
    assert_not jurisdiction.valid?
    assert_includes jurisdiction.errors[:boundary], "can't be blank"
  end

  test "should store and retrieve PostGIS geometry" do
    boundary_wkt = "POLYGON((-122.4 37.8, -122.4 37.7, -122.3 37.7, -122.3 37.8, -122.4 37.8))"
    jurisdiction = Jurisdiction.create!(
      name: "San Francisco",
      boundary: boundary_wkt
    )

    # Reload from database
    jurisdiction.reload

    # Check that boundary is stored as geometry
    assert_not_nil jurisdiction.boundary
    assert_equal "San Francisco", jurisdiction.name
  end

  test "should be able to check if a point is within boundary" do
    # Create a simple square boundary
    boundary_wkt = "POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))"
    jurisdiction = Jurisdiction.create!(
      name: "Test Square",
      boundary: boundary_wkt
    )

    # Point inside the boundary
    point_inside = "POINT(5 5)"
    assert jurisdiction.contains_point?(point_inside)

    # Point outside the boundary
    point_outside = "POINT(15 15)"
    assert_not jurisdiction.contains_point?(point_outside)
  end
end
