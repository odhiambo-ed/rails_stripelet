class Product < ApplicationRecord
  include Identifiable

  validates :name, presence: true
  validates :product_id, uniqueness: true

  has_many :prices, dependent: :destroy

  scope :active, -> { where(active: true, deleted_at: nil) }
end
