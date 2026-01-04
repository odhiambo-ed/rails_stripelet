class Subscription < ApplicationRecord
  include Identifiable

  enum :status, { trialing: "trialing", active: "active", past_due: "past_due", canceled: "canceled", paused: "paused" }, prefix: true

  belongs_to :customer
  belongs_to :price
  has_many :invoices, dependent: :destroy

  validates :subscription_id, uniqueness: true
  validates :status, presence: true
  validates :current_period_start, presence: true
  validates :current_period_end, presence: true
  validates :next_billing_date, presence: true
  validates :customer_id, presence: true
  validates :price_id, presence: true

  scope :active, -> { where(status: "active", deleted_at: nil) }
  scope :trialing, -> { where(status: "trialing", deleted_at: nil) }
  scope :due_for_renewal, -> { where("next_billing_date <= ? AND status IN (?, ?)", Date.current, "active", "trialing").where(deleted_at: nil) }

  def in_trial?
    status_trialing? && trial_end_at.present? && trial_end_at > Time.current
  end

  def days_until_renewal
    (next_billing_date - Date.current).to_i
  end
end
