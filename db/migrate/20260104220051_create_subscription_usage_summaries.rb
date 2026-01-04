class CreateSubscriptionUsageSummaries < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_usage_summaries do |t|
      # Subscription being summarized
      t.references :subscription, null: false, foreign_key: true

      # Metric being summarized (api_calls, storage_gb, etc.)
      t.string :metric, null: false

      # Period covered by this summary
      t.date :period_start, null: false
      t.date :period_end, null: false

      # Total quantity for this period
      t.decimal :total_quantity, null: false, default: 0, precision: 15, scale: 5

      # Last time events were aggregated into this summary
      t.datetime :last_aggregated_at

      # Additional data
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    # =====================
    # Indexes
    # =====================
    # Unique constraint on (subscription_id, metric, period_start, period_end)
    add_index :subscription_usage_summaries,
              [ :subscription_id, :metric, :period_start, :period_end ],
              unique: true,
              name: "idx_usage_summaries_unique"

    add_index :subscription_usage_summaries, :metric
    add_index :subscription_usage_summaries, [ :period_start, :period_end ],
              name: "idx_usage_summaries_period"

    # =====================
    # Constraints
    # =====================
    add_check_constraint :subscription_usage_summaries,
      "total_quantity >= 0",
      name: "chk_usage_summary_quantity_non_negative"

    add_check_constraint :subscription_usage_summaries,
      "period_end >= period_start",
      name: "chk_usage_summary_period_order"

    # =====================
    # Comments
    # =====================
    change_table_comment :subscription_usage_summaries,
      "Aggregated usage summaries by subscription, metric, and period"

    change_column_comment :subscription_usage_summaries, :metric,
      "Metric being tracked (e.g., 'api_calls', 'storage_gb')"

    change_column_comment :subscription_usage_summaries, :total_quantity,
      "Sum of all usage events for this subscription/metric/period"

    change_column_comment :subscription_usage_summaries, :last_aggregated_at,
      "Last time new events were added to this summary"
  end
end
