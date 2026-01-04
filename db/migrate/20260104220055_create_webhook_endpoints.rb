class CreateWebhookEndpoints < ActiveRecord::Migration[8.0]
  def change
    create_table :webhook_endpoints do |t|
      # Unique endpoint identifier
      t.string :endpoint_id, null: false

      # HTTPS URL to send webhooks to
      t.string :url, null: false

      # Bcrypt hashed secret for signature verification
      t.string :secret_digest, null: false

      # Array of event types this endpoint subscribes to
      t.text :events, array: true, default: [], null: false

      # Whether this endpoint is active
      t.boolean :active, default: true, null: false

      # Additional endpoint data
      t.jsonb :metadata, default: {}, null: false

      # Soft delete
      t.datetime :deleted_at

      t.timestamps
    end

    # =====================
    # Indexes
    # =====================
    add_index :webhook_endpoints, :endpoint_id, unique: true
    add_index :webhook_endpoints, :active
    add_index :webhook_endpoints, :deleted_at

    # =====================
    # Constraints
    # =====================
    # Ensure URL starts with https://
    add_check_constraint :webhook_endpoints,
      "url ~ '^https://'",
      name: "chk_webhook_endpoint_https_url"

    add_check_constraint :webhook_endpoints,
      "url != ''",
      name: "chk_webhook_endpoint_url_not_empty"

    # =====================
    # Comments
    # =====================
    change_table_comment :webhook_endpoints,
      "Webhook endpoints that receive event notifications"

    change_column_comment :webhook_endpoints, :endpoint_id,
      "External-facing endpoint identifier (we_xxx)"

    change_column_comment :webhook_endpoints, :url,
      "HTTPS URL to send webhook events to"

    change_column_comment :webhook_endpoints, :secret_digest,
      "Bcrypt hash of the webhook secret for signature verification"

    change_column_comment :webhook_endpoints, :events,
      "Array of event types this endpoint subscribes to"

    change_column_comment :webhook_endpoints, :active,
      "Whether this endpoint is currently active"
  end
end
