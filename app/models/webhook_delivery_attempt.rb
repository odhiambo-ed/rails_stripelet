# WebhookDeliveryAttempt tracks individual delivery attempts of events to endpoints
class WebhookDeliveryAttempt < ApplicationRecord
  # Enums
  enum :status, { pending: "pending", success: "success", failed: "failed" }, prefix: true

  # Associations
  belongs_to :webhook_event
  belongs_to :webhook_endpoint

  # Validations
  validates :webhook_event_id, presence: true
  validates :webhook_endpoint_id, presence: true
  validates :attempt_number, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true
  validates :attempted_at, presence: true

  # Validate uniqueness of attempt_number per event/endpoint
  validates :attempt_number, uniqueness: { scope: [ :webhook_event_id, :webhook_endpoint_id ] }

  # Scopes
  scope :successful, -> { where(status: "success") }
  scope :failed, -> { where(status: "failed") }
  scope :recent, -> { order(attempted_at: :desc) }

  # Mark attempt as successful
  def mark_as_success!(response_code, response_body = nil)
    update!(
      status: "success",
      response_code: response_code,
      response_body: response_body&.truncate(1000)
    )
  end

  # Mark attempt as failed
  def mark_as_failed!(response_code = nil, response_body = nil)
    update!(
      status: "failed",
      response_code: response_code,
      response_body: response_body&.truncate(1000)
    )
  end
end
