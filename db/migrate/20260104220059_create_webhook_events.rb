class CreateWebhookEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :webhook_events do |t|
      # Unique event identifier
      t.string :event_id, null: false

      # Type of event (invoice.paid, subscription.created, etc.)
      t.string :event_type, null: false

      # Event payload (the actual data)
      t.jsonb :payload, null: false

      # Whether this event has been successfully delivered to at least one endpoint
      t.boolean :delivered, default: false, null: false

      # Number of delivery attempts across all endpoints
      t.integer :attempts_count, default: 0, null: false

      # Additional event metadata
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    # =====================
    # Indexes
    # =====================
    add_index :webhook_events, :event_id, unique: true
    add_index :webhook_events, :event_type
    add_index :webhook_events, :delivered
    add_index :webhook_events, :created_at

    # Index for finding undelivered events
    add_index :webhook_events,
              :created_at,
              where: "delivered = false",
              name: "idx_webhook_events_undelivered"

    # =====================
    # Constraints
    # =====================
    add_check_constraint :webhook_events,
      "attempts_count >= 0",
      name: "chk_webhook_event_attempts_non_negative"

    # =====================
    # Comments
    # =====================
    change_table_comment :webhook_events,
      "Webhook events to be delivered to subscribed endpoints"

    change_column_comment :webhook_events, :event_id,
      "Unique event identifier (evt_xxx)"

    change_column_comment :webhook_events, :event_type,
      "Type of event (e.g., 'invoice.paid', 'subscription.created')"

    change_column_comment :webhook_events, :payload,
      "Event payload containing the actual event data"

    change_column_comment :webhook_events, :delivered,
      "Whether this event has been successfully delivered to at least one endpoint"

    change_column_comment :webhook_events, :attempts_count,
      "Total number of delivery attempts across all endpoints"
  end
end
