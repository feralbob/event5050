class Organization < ApplicationRecord
  has_many :org_users, dependent: :destroy
  has_many :licenses, dependent: :destroy
  has_many :raffles, dependent: :destroy

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
end
