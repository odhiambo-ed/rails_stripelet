class Price < ApplicationRecord
  include Identifiable

  enum :currency, { usd: "usd", eur: "eur", gbp: "gbp", jpy: "jpy" }, prefix: true
  enum :interval, { day: "day", week: "week", month: "month", year: "year" }, prefix: true
  enum :billing_scheme, { per_unit: "per_unit", tiered: "tiered" }, prefix: true

  belongs_to :product
  has_many :subscriptions, dependent: :nullify

  validates :price_id, uniqueness: true
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :interval, presence: true
  validates :interval_count, presence: true, numericality: { greater_than: 0 }
  validates :billing_scheme, presence: true
  validates :product_id, presence: true

  scope :active, -> { where(active: true, deleted_at: nil) }
end
