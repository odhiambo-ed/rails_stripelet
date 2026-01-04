# Refund represents money returned to a customer for an invoice
class Refund < ApplicationRecord
  include Identifiable

  # Enums
  enum :status, { pending: "pending", succeeded: "succeeded", failed: "failed", canceled: "canceled" }, prefix: true
  enum :currency, { usd: "usd", eur: "eur", gbp: "gbp", jpy: "jpy" }, prefix: true

  # Associations
  belongs_to :invoice

  # Validations
  validates :refund_id, uniqueness: true
  validates :invoice_id, presence: true
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :status, presence: true

  # Scopes
  scope :successful, -> { where(status: "succeeded") }
  scope :pending, -> { where(status: "pending") }
  scope :by_invoice, ->(invoice) { where(invoice: invoice) }

  # Mark refund as succeeded
  def mark_as_succeeded!
    update!(status: "succeeded")
  end

  # Mark refund as failed
  def mark_as_failed!
    update!(status: "failed")
  end

  # Mark refund as canceled
  def cancel!
    update!(status: "canceled")
  end
end
