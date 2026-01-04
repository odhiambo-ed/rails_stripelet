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

ActiveRecord::Schema[8.0].define(version: 2026_01_04_004135) do
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
end
