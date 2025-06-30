class WebauthnCredential < ApplicationRecord
  belongs_to :customer

  validates :external_id, presence: true, uniqueness: true
  validates :public_key, presence: true
  validates :sign_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :recently_used, -> { order(Arel.sql("last_used_at DESC NULLS LAST")) }

  def credential_id
    external_id
  end

  def public_key_object
    Base64.strict_decode64(public_key)
  end
end
