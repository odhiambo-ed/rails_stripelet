# WebhookEndpoint represents a URL that receives webhook event notifications
class WebhookEndpoint < ApplicationRecord
  include Identifiable

  # Associations
  has_many :webhook_delivery_attempts, dependent: :destroy

  # Validations
  validates :endpoint_id, uniqueness: true
  validates :url, presence: true, format: { with: /\Ahttps:\/\//, message: "must start with https://" }
  validates :secret_digest, presence: true
  validates :events, presence: true

  # Scopes
  scope :active, -> { where(active: true, deleted_at: nil) }
  scope :subscribes_to, ->(event_type) { where("? = ANY(events)", event_type) }

  # Check if endpoint subscribes to an event type
  def subscribes_to?(event_type)
    events.include?(event_type)
  end

  # Activate this endpoint
  def activate!
    update!(active: true)
  end

  # Deactivate this endpoint
  def deactivate!
    update!(active: false)
  end

  # Check if endpoint is active
  def active?
    active && deleted_at.nil?
  end
end
