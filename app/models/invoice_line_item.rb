class InvoiceLineItem < ApplicationRecord
  enum :currency, { usd: "usd", eur: "eur", gbp: "gbp", jpy: "jpy" }, prefix: true

  belongs_to :invoice

  validates :description, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validates :invoice_id, presence: true

  scope :by_currency, ->(currency) { where(currency: currency) }
end
