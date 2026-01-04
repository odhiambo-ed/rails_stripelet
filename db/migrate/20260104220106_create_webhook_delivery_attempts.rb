class CreateWebhookDeliveryAttempts < ActiveRecord::Migration[8.0]
  def change
    create_table :webhook_delivery_attempts do |t|
      # Event being delivered
      t.references :webhook_event, null: false, foreign_key: true

      # Endpoint receiving the delivery
      t.references :webhook_endpoint, null: false, foreign_key: true

      # Which attempt number this is (1, 2, 3...)
      t.integer :attempt_number, null: false

      # Status of this attempt (pending, success, failed)
      t.string :status, null: false

      # HTTP response code
      t.integer :response_code

      # HTTP response body (truncated)
      t.text :response_body

      # When this attempt was made
      t.datetime :attempted_at, null: false

      t.timestamps
    end

    # =====================
    # Indexes
    # =====================
    add_index :webhook_delivery_attempts, :status
    add_index :webhook_delivery_attempts, :attempted_at
    add_index :webhook_delivery_attempts, [ :webhook_event_id, :webhook_endpoint_id, :attempt_number ],
              unique: true,
              name: "idx_webhook_attempts_unique"

    # Index for finding failed attempts to retry
    add_index :webhook_delivery_attempts,
              [ :webhook_event_id, :status ],
              where: "status = 'failed'",
              name: "idx_webhook_attempts_failed"

    # =====================
    # Constraints
    # =====================
    add_check_constraint :webhook_delivery_attempts,
      "status IN ('pending', 'success', 'failed')",
      name: "chk_webhook_attempt_status_valid"

    add_check_constraint :webhook_delivery_attempts,
      "attempt_number > 0",
      name: "chk_webhook_attempt_number_positive"

    add_check_constraint :webhook_delivery_attempts,
      "response_code IS NULL OR (response_code >= 100 AND response_code < 600)",
      name: "chk_webhook_attempt_response_code_valid"

    # =====================
    # Comments
    # =====================
    change_table_comment :webhook_delivery_attempts,
      "Individual delivery attempts of webhook events to endpoints"

    change_column_comment :webhook_delivery_attempts, :attempt_number,
      "Attempt number for this event/endpoint combination (1, 2, 3...)"

    change_column_comment :webhook_delivery_attempts, :status,
      "Status of this delivery attempt (pending, success, failed)"

    change_column_comment :webhook_delivery_attempts, :response_code,
      "HTTP response code from the endpoint"

    change_column_comment :webhook_delivery_attempts, :response_body,
      "HTTP response body from the endpoint (truncated for storage)"

    change_column_comment :webhook_delivery_attempts, :attempted_at,
      "When this delivery attempt was made"
  end
end
