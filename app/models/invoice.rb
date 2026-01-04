class Invoice < ApplicationRecord
  include Identifiable

  enum :status, { draft: "draft", open: "open", paid: "paid", void: "void", uncollectible: "uncollectible", partially_refunded: "partially_refunded", refunded: "refunded" }, prefix: true
  enum :currency, { usd: "usd", eur: "eur", gbp: "gbp", jpy: "jpy" }, prefix: true

  belongs_to :customer
  belongs_to :subscription
  has_many :line_items, class_name: "InvoiceLineItem", dependent: :destroy

  validates :invoice_id, uniqueness: true
  validates :status, presence: true
  validates :currency, presence: true
  validates :subtotal_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :tax_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :amount_paid_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :amount_refunded_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :amount_due_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :period_start, presence: true
  validates :period_end, presence: true
  validates :customer_id, presence: true
  validates :subscription_id, presence: true

  scope :open, -> { where(status: "open", deleted_at: nil) }
  scope :paid, -> { where(status: "paid", deleted_at: nil) }
  scope :overdue, -> { where("due_date < ? AND status = ? AND deleted_at IS NULL", Date.current, "open") }

  def finalize!
    return if finalized_at.present?
    update!(status: "open", finalized_at: Time.current)
  end

  def mark_paid!
    update!(status: "paid", paid_at: Time.current, amount_due_cents: 0)
  end

  def readonly?
    finalized_at.present?
  end
end
