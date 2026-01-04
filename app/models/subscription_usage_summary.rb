# SubscriptionUsageSummary aggregates usage events by subscription, metric, and period
class SubscriptionUsageSummary < ApplicationRecord
  # Associations
  belongs_to :subscription

  # Validations
  validates :subscription_id, presence: true
  validates :metric, presence: true
  validates :period_start, presence: true
  validates :period_end, presence: true
  validates :total_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Validate uniqueness of subscription + metric + period
  validates :metric, uniqueness: { scope: [ :subscription_id, :period_start, :period_end ] }

  # Scopes
  scope :by_metric, ->(metric) { where(metric: metric) }
  scope :for_period, ->(start_date, end_date) { where(period_start: start_date, period_end: end_date) }
  scope :current_period, -> { where("period_start <= ? AND period_end >= ?", Date.current, Date.current) }

  # Increment the total quantity
  def increment_quantity!(amount)
    increment!(:total_quantity, amount)
    touch(:last_aggregated_at)
  end

  # Reset quantity to zero
  def reset_quantity!
    update!(total_quantity: 0, last_aggregated_at: Time.current)
  end
end
