class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.string :subscription_id
      t.references :customer, null: false, foreign_key: true
      t.references :price, null: false, foreign_key: true
      t.string :status
      t.date :current_period_start
      t.date :current_period_end
      t.datetime :trial_start_at
      t.datetime :trial_end_at
      t.datetime :cancel_at
      t.datetime :canceled_at
      t.date :next_billing_date
      t.jsonb :metadata

      t.timestamps
    end

    # =====================
    # Indexes
    # =====================
    add_index :subscriptions, :subscription_id, unique: true
    add_index :subscriptions, :customer_id
    add_index :subscriptions, :status

    add_index :subscriptions,
              :next_billing_date,
              where: "status IN ('active', 'trialing')",
              name: "idx_subscriptions_next_billing_date"

    add_index :subscriptions,
              :trial_end_at,
              where: "status = 'trialing'",
              name: "idx_subscriptions_trial_end"

    add_index :subscriptions,
              :cancel_at,
              where: "cancel_at IS NOT NULL",
              name: "idx_subscriptions_cancel_at"

    # =====================
    # Constraints
    # =====================
    add_check_constraint :subscriptions,
      "status IN ('trialing', 'active', 'past_due', 'canceled', 'paused')",
      name: "chk_subscription_status"

    add_check_constraint :subscriptions,
      "current_period_end > current_period_start",
      name: "chk_subscription_period_order"

    # =====================
    # Comments
    # =====================
    change_table_comment :subscriptions,
      "Recurring billing subscriptions"

    change_column_comment :subscriptions, :status,
      "Current subscription status"

    change_column_comment :subscriptions, :cancel_at,
      "Scheduled cancellation date (end of period)"

    change_column_comment :subscriptions, :canceled_at,
      "Actual cancellation timestamp"
  end
end
