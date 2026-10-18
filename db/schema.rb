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

ActiveRecord::Schema[8.1].define(version: 2026_10_16_151831) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "groups", force: :cascade do |t|
    t.string "name", null: false
    t.string "public_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["public_id"], name: "index_groups_on_public_id", unique: true
  end

  create_table "measurements", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "metric_type", null: false
    t.date "recorded_on", null: false
    t.datetime "recorded_at", null: false
    t.decimal "value", precision: 6, scale: 1, null: false
    t.decimal "value_secondary", precision: 6, scale: 1
    t.uuid "idempotency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["idempotency_key", "metric_type"], name: "index_measurements_on_idempotency_key_and_metric_type", unique: true
    t.index ["user_id", "metric_type", "recorded_on", "recorded_at"], name: "idx_on_user_id_metric_type_recorded_on_recorded_at_c4de3cbce9"
    t.index ["user_id"], name: "index_measurements_on_user_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "user_id", null: false
    t.integer "role", default: 0, null: false
    t.datetime "joined_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "user_id"], name: "index_memberships_on_group_id_and_user_id", unique: true
    t.index ["group_id"], name: "index_memberships_on_group_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_name", default: "", null: false
    t.integer "sex"
    t.date "birth_date"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "measurements", "users"
  add_foreign_key "memberships", "groups"
  add_foreign_key "memberships", "users"
end
