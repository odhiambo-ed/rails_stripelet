# UsageEvent tracks individual usage occurrences for metered billing
class UsageEvent < ApplicationRecord
  # Associations
  belongs_to :subscription

  # Validations
  validates :event_id, presence: true, uniqueness: true
  validates :subscription_id, presence: true
  validates :metric_name, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :timestamp, presence: true

  # Scopes
  scope :unprocessed, -> { where(processed_at: nil) }
  scope :processed, -> { where.not(processed_at: nil) }
  scope :by_metric, ->(metric) { where(metric_name: metric) }
  scope :in_period, ->(start_date, end_date) { where(timestamp: start_date..end_date) }

  # Mark this event as processed
  def mark_as_processed!
    update!(processed_at: Time.current)
  end

  # Check if event has been processed
  def processed?
    processed_at.present?
  end
end
