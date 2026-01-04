class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :product_id, null: false
      t.string :name, null: false
      t.text :description
      t.boolean :active, default: true, null: false
      t.jsonb :metadata, default: {}, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    # Unique constraints
    add_index :products, :product_id, unique: true
    add_index :products, :name, unique: true, where: "deleted_at IS NULL"

    # Performance indexes
    add_index :products, :active
    add_index :products, :created_at
    add_index :products, [ :active, :created_at ]

    # Check constraints
    add_check_constraint :products, "name != ''", name: "products_name_not_empty"

    # Comments
    change_table_comment :products,
      "Billable products/services that customers can subscribe to"

    change_column_comment :products, :product_id,
      "External-facing product identifier (prod_xxx)"

    change_column_comment :products, :metadata,
      "Flexible JSONB storage for custom attributes (features, tiers, etc.)"

    change_column_comment :products, :deleted_at,
      "Soft delete timestamp for archiving products"
  end
end
