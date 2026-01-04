class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.string :subscription_id, null: false
      t.references :customer, null: false, foreign_key: true
      t.references :price, null: false, foreign_key: true
      t.string :status, null: false, default: 'trialing'
      t.date :current_period_start, null: false
      t.date :current_period_end, null: false
      t.datetime :trial_start_at
      t.datetime :trial_end_at
      t.datetime :cancel_at
      t.datetime :canceled_at
      t.date :next_billing_date, null: false
      t.jsonb :metadata, default: {}, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    # =====================
    # Indexes
    # =====================
    add_index :subscriptions, :subscription_id, unique: true
    add_index :subscriptions, :status

    # Partial indexes on status for performance
    add_index :subscriptions,
              :next_billing_date,
              where: "status IN ('active', 'trialing') AND deleted_at IS NULL",
              name: "idx_subscriptions_next_billing_active"

    add_index :subscriptions,
              :trial_end_at,
              where: "status = 'trialing' AND deleted_at IS NULL",
              name: "idx_subscriptions_trial_end_active"

    add_index :subscriptions,
              :cancel_at,
              where: "cancel_at IS NOT NULL AND deleted_at IS NULL",
              name: "idx_subscriptions_cancel_at_pending"

    add_index :subscriptions, [ :customer_id, :status ]
    add_index :subscriptions, [ :customer_id, :deleted_at ]

    # =====================
    # Constraints
    # =====================
    add_check_constraint :subscriptions,
      "status IN ('trialing', 'active', 'past_due', 'canceled', 'paused')",
      name: "chk_subscription_status_valid"

    add_check_constraint :subscriptions,
      "current_period_end > current_period_start",
      name: "chk_subscription_period_order"

    add_check_constraint :subscriptions,
      "next_billing_date >= current_period_end",
      name: "chk_subscription_billing_date_order"

    # =====================
    # Comments
    # =====================
    change_table_comment :subscriptions,
      "Recurring billing subscriptions linking customers to pricing"

    change_column_comment :subscriptions, :subscription_id,
      "External-facing subscription identifier (sub_xxx)"

    change_column_comment :subscriptions, :status,
      "Current subscription status (trialing, active, past_due, canceled, paused)"

    change_column_comment :subscriptions, :current_period_start,
      "Start date of current billing period"

    change_column_comment :subscriptions, :current_period_end,
      "End date of current billing period"

    change_column_comment :subscriptions, :trial_start_at,
      "When trial period began (if applicable)"

    change_column_comment :subscriptions, :trial_end_at,
      "When trial period ends (if applicable)"

    change_column_comment :subscriptions, :cancel_at,
      "Scheduled cancellation date (end of period)"

    change_column_comment :subscriptions, :canceled_at,
      "Actual cancellation timestamp (when status changed to canceled)"

    change_column_comment :subscriptions, :next_billing_date,
      "Next scheduled billing date"

    change_column_comment :subscriptions, :metadata,
      "Flexible JSONB storage for custom subscription attributes"
  end
end
