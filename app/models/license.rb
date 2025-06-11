class License < ApplicationRecord
  belongs_to :organization
  belongs_to :jurisdiction
  
  validates :license_number, presence: true, uniqueness: true
  validates :issued_at, presence: true
  validates :expires_at, presence: true
  validate :expires_at_after_issued_at
  
  # Enums
  enum :license_type, { single: 0, recurring: 1 }
  
  def active?
    return false unless issued_at && expires_at
    current_date = Date.current
    current_date >= issued_at && current_date <= expires_at
  end
  
  private
  
  def expires_at_after_issued_at
    return unless issued_at && expires_at
    
    if expires_at <= issued_at
      errors.add(:expires_at, "must be after issued date")
    end
  end
end
