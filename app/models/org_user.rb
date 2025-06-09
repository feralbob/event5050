class OrgUser < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :organization

  enum :role, { admin: 0, finance: 1, legal: 2, support: 3 }

  validates :first_name, presence: true
  validates :last_name, presence: true

  # Set up acts_as_tenant
  acts_as_tenant :organization
end
