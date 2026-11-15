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

ActiveRecord::Schema[8.1].define(version: 2026_11_15_222953) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "contributions", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "invitation_id"
    t.string "name", null: false
    t.string "category", default: "other", null: false
    t.integer "cost_cents", default: 0, null: false
    t.boolean "shared", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_contributions_on_event_id"
    t.index ["invitation_id"], name: "index_contributions_on_invitation_id"
  end

  create_table "events", force: :cascade do |t|
    t.bigint "host_id", null: false
    t.string "title", null: false
    t.text "description"
    t.datetime "starts_at", null: false
    t.string "location"
    t.string "invite_token", null: false
    t.string "status", default: "planning", null: false
    t.boolean "round_to_whole_dollars", default: false, null: false
    t.integer "forgive_under_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["host_id"], name: "index_events_on_host_id"
    t.index ["invite_token"], name: "index_events_on_invite_token", unique: true
  end

  create_table "invitations", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "user_id"
    t.string "guest_name", null: false
    t.string "email"
    t.string "access_token", null: false
    t.string "rsvp_status", default: "pending", null: false
    t.string "venmo_username"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_token"], name: "index_invitations_on_access_token", unique: true
    t.index ["event_id", "user_id"], name: "index_invitations_on_event_id_and_user_id", unique: true, where: "(user_id IS NOT NULL)"
    t.index ["event_id"], name: "index_invitations_on_event_id"
    t.index ["user_id"], name: "index_invitations_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settlements", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "from_invitation_id", null: false
    t.bigint "to_invitation_id", null: false
    t.integer "amount_cents", null: false
    t.datetime "paid_at"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_settlements_on_event_id"
    t.index ["from_invitation_id"], name: "index_settlements_on_from_invitation_id"
    t.index ["to_invitation_id"], name: "index_settlements_on_to_invitation_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "name", null: false
    t.string "venmo_username"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "contributions", "events"
  add_foreign_key "contributions", "invitations"
  add_foreign_key "events", "users", column: "host_id"
  add_foreign_key "invitations", "events"
  add_foreign_key "invitations", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "settlements", "events"
  add_foreign_key "settlements", "invitations", column: "from_invitation_id"
  add_foreign_key "settlements", "invitations", column: "to_invitation_id"
end
