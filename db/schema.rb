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

ActiveRecord::Schema[8.0].define(version: 2025_06_11_012525) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"
  enable_extension "postgis"

  create_table "draws", force: :cascade do |t|
    t.bigint "raffle_id", null: false
    t.date "draw_date"
    t.datetime "ticket_sales_start_at"
    t.datetime "ticket_sales_end_at"
    t.string "status"
    t.integer "total_revenue_cents"
    t.jsonb "prize_pool"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["raffle_id"], name: "index_draws_on_raffle_id"
  end

  create_table "jurisdictions", force: :cascade do |t|
    t.string "name"
    t.geometry "boundary", limit: {srid: 0, type: "geometry"}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["boundary"], name: "index_jurisdictions_on_boundary", using: :gist
    t.index ["name"], name: "index_jurisdictions_on_name", unique: true
  end

  create_table "licenses", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "jurisdiction_id", null: false
    t.string "license_number"
    t.date "issued_at"
    t.date "expires_at"
    t.string "license_type"
    t.date "event_date"
    t.string "recurrence_rule"
    t.jsonb "requirements"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jurisdiction_id"], name: "index_licenses_on_jurisdiction_id"
    t.index ["license_number"], name: "index_licenses_on_license_number", unique: true
    t.index ["organization_id"], name: "index_licenses_on_organization_id"
  end

  create_table "org_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.bigint "organization_id", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_org_users_on_email", unique: true
    t.index ["organization_id"], name: "index_org_users_on_organization_id"
    t.index ["reset_password_token"], name: "index_org_users_on_reset_password_token", unique: true
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_organizations_on_name", unique: true
  end

  create_table "raffles", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "license_id", null: false
    t.string "name"
    t.text "description"
    t.string "status"
    t.boolean "recurring"
    t.string "recurrence_rule"
    t.jsonb "ticket_pricing"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["license_id"], name: "index_raffles_on_license_id"
    t.index ["organization_id"], name: "index_raffles_on_organization_id"
  end

  create_table "ticket_purchasers", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_ticket_purchasers_on_email"
  end

  create_table "tickets", force: :cascade do |t|
    t.bigint "draw_id", null: false
    t.bigint "ticket_purchaser_id", null: false
    t.string "ticket_number"
    t.integer "price_cents"
    t.string "status"
    t.string "prize_won"
    t.jsonb "purchase_metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["draw_id"], name: "index_tickets_on_draw_id"
    t.index ["ticket_number"], name: "index_tickets_on_ticket_number", unique: true
    t.index ["ticket_purchaser_id"], name: "index_tickets_on_ticket_purchaser_id"
  end

  add_foreign_key "draws", "raffles"
  add_foreign_key "licenses", "jurisdictions"
  add_foreign_key "licenses", "organizations"
  add_foreign_key "org_users", "organizations"
  add_foreign_key "raffles", "licenses"
  add_foreign_key "raffles", "organizations"
  add_foreign_key "tickets", "draws"
  add_foreign_key "tickets", "ticket_purchasers"
end
