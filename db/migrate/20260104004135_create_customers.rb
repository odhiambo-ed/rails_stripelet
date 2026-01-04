class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.string :customer_id
      t.string :email
      t.string :name
      t.string :currency
      t.jsonb :metadata
      t.datetime :deleted_at

      t.timestamps
    end

    # Indexes
    add_index :customers, :customer_id, unique: true
    add_index :customers, :created_at

    # Partial unique index (soft delete safe)
    add_index :customers,
              :email,
              unique: true,
              where: "deleted_at IS NULL",
              name: "idx_customers_email"

    # Comments (Postgres only, but Rails supports it)
    change_table_comment :customers,
      "Customer accounts that can have subscriptions and be billed"

    change_column_comment :customers, :customer_id,
      "External-facing customer identifier (cus_xxx)"

    change_column_comment :customers, :metadata,
      "Flexible JSONB storage for custom attributes"
  end
end
