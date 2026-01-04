# WebhookEvent represents an event to be delivered to webhook endpoints
class WebhookEvent < ApplicationRecord
  include Identifiable

  # Associations
  has_many :webhook_delivery_attempts, dependent: :destroy

  # Validations
  validates :event_id, uniqueness: true
  validates :event_type, presence: true
  validates :payload, presence: true
  validates :attempts_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :delivered, -> { where(delivered: true) }
  scope :undelivered, -> { where(delivered: false) }
  scope :by_type, ->(type) { where(event_type: type) }
  scope :recent, -> { order(created_at: :desc) }

  # Mark event as delivered
  def mark_as_delivered!
    update!(delivered: true)
  end

  # Increment attempts count
  def increment_attempts!
    increment!(:attempts_count)
  end

  # Check if delivery should be retried
  def retry_delivery?
    !delivered && attempts_count < 3
  end
end
