class Jurisdiction < ApplicationRecord
  has_many :licenses, dependent: :restrict_with_error
  
  validates :name, presence: true, uniqueness: true
  validates :boundary, presence: true

  def contains_point?(point_wkt)
    return false unless boundary.present?
    
    # Use PostGIS ST_Contains function to check if point is within boundary
    # We don't specify SRID in ST_GeomFromText to match the boundary's SRID
    sql = "SELECT ST_Contains(boundary, ST_GeomFromText(?)) FROM jurisdictions WHERE id = ?"
    result = self.class.connection.select_value(
      self.class.sanitize_sql_array([sql, point_wkt, id])
    )
    
    ActiveModel::Type::Boolean.new.cast(result)
  end
end
