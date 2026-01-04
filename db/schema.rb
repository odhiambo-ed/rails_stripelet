# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_01_04_195817) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "customers", comment: "Customer accounts that can have subscriptions and be billed", force: :cascade do |t|
    t.string "customer_id", comment: "External-facing customer identifier (cus_xxx)"
    t.string "email"
    t.string "name"
    t.string "currency"
    t.jsonb "metadata", comment: "Flexible JSONB storage for custom attributes"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_customers_on_created_at"
    t.index ["customer_id"], name: "index_customers_on_customer_id", unique: true
    t.index ["email"], name: "idx_customers_email", unique: true, where: "(deleted_at IS NULL)"
  end

  create_table "products", comment: "Billable products/services that customers can subscribe to", force: :cascade do |t|
    t.string "product_id", null: false, comment: "External-facing product identifier (prod_xxx)"
    t.string "name", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.jsonb "metadata", default: {}, null: false, comment: "Flexible JSONB storage for custom attributes (features, tiers, etc.)"
    t.datetime "deleted_at", comment: "Soft delete timestamp for archiving products"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "created_at"], name: "index_products_on_active_and_created_at"
    t.index ["active"], name: "index_products_on_active"
    t.index ["created_at"], name: "index_products_on_created_at"
    t.index ["name"], name: "index_products_on_name", unique: true, where: "(deleted_at IS NULL)"
    t.index ["product_id"], name: "index_products_on_product_id", unique: true
    t.check_constraint "name::text <> ''::text", name: "products_name_not_empty"
  end
end
