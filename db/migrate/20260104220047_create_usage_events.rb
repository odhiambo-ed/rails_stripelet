class CreateUsageEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :usage_events do |t|
      # Unique event identifier
      t.string :event_id, null: false

      # Subscription this usage belongs to
      t.references :subscription, null: false, foreign_key: true

      # Metric being tracked (api_calls, storage_gb, etc.)
      t.string :metric_name, null: false

      # Quantity of usage
      t.decimal :quantity, null: false, precision: 15, scale: 5

      # When the usage occurred
      t.datetime :timestamp, null: false

      # When this event was aggregated into summaries
      t.datetime :processed_at

      # Additional event data
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    # =====================
    # Indexes
    # =====================
    add_index :usage_events, :event_id, unique: true
    add_index :usage_events, :metric_name
    add_index :usage_events, :timestamp

    # Index for finding unprocessed events
    add_index :usage_events,
              :processed_at,
              where: "processed_at IS NULL",
              name: "idx_usage_events_unprocessed"

    # Composite index for subscription queries
    add_index :usage_events, [ :subscription_id, :metric_name, :timestamp ],
              name: "idx_usage_events_sub_metric_time"

    # =====================
    # Constraints
    # =====================
    add_check_constraint :usage_events,
      "quantity > 0",
      name: "chk_usage_event_quantity_positive"

    # Ensure timestamp is within last 24 hours for real-time processing
    add_check_constraint :usage_events,
      "timestamp >= NOW() - INTERVAL '24 hours'",
      name: "chk_usage_event_timestamp_recent"

    # =====================
    # Comments
    # =====================
    change_table_comment :usage_events,
      "Individual usage events (API calls, storage, etc.) for metered billing"

    change_column_comment :usage_events, :event_id,
      "Unique event identifier for idempotency"

    change_column_comment :usage_events, :metric_name,
      "Name of the metric being tracked (e.g., 'api_calls', 'storage_gb')"

    change_column_comment :usage_events, :quantity,
      "Quantity of usage (e.g., 1 API call, 2.5 GB storage)"

    change_column_comment :usage_events, :timestamp,
      "When the usage occurred (must be within last 24 hours)"

    change_column_comment :usage_events, :processed_at,
      "When this event was aggregated into subscription_usage_summaries"
  end
end
