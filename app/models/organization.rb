class Organization < ApplicationRecord
  has_many :org_users, dependent: :destroy

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
end
