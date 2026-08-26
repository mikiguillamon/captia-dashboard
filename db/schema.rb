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

ActiveRecord::Schema[8.1].define(version: 2026_08_26_070850) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_effective_id", null: false
    t.bigint "actor_real_id", null: false
    t.datetime "created_at", null: false
    t.inet "ip"
    t.bigint "subject_id"
    t.string "subject_type"
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["actor_effective_id"], name: "index_audit_logs_on_actor_effective_id"
    t.index ["actor_real_id"], name: "index_audit_logs_on_actor_real_id"
    t.index ["subject_type", "subject_id"], name: "index_audit_logs_on_subject"
  end

  create_table "invitations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "expires_at", null: false
    t.bigint "invited_by_id", null: false
    t.bigint "organization_id", null: false
    t.string "role", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["organization_id", "email"], name: "index_invitations_on_organization_id_and_email"
    t.index ["organization_id"], name: "index_invitations_on_organization_id"
    t.index ["token_digest"], name: "index_invitations_on_token_digest", unique: true
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
    t.index ["user_id", "organization_id"], name: "index_memberships_on_user_id_and_organization_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "mfa_enrollments", force: :cascade do |t|
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.integer "last_used_timestep", default: 0, null: false
    t.text "secret", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_mfa_enrollments_on_user_id", unique: true
  end

  create_table "organizations", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "allow_self_invite", default: false, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.boolean "require_mfa", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_organizations_on_account_id"
  end

  create_table "password_reset_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.bigint "user_id", null: false
    t.index ["token_digest"], name: "index_password_reset_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_password_reset_tokens_on_user_id"
  end

  create_table "recovery_codes", force: :cascade do |t|
    t.string "code_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.bigint "user_id", null: false
    t.index ["user_id", "code_digest"], name: "index_recovery_codes_on_user_id_and_code_digest"
    t.index ["user_id"], name: "index_recovery_codes_on_user_id"
  end

  create_table "role_assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "exception"
    t.string "role", null: false
    t.integer "scope_id", null: false
    t.string "scope_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["scope_type", "scope_id"], name: "index_role_assignments_on_scope_type_and_scope_id"
    t.index ["user_id", "scope_type", "scope_id"], name: "index_role_assignments_on_user_id_and_scope_type_and_scope_id"
    t.index ["user_id"], name: "index_role_assignments_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "account_id"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "audit_logs", "users", column: "actor_effective_id"
  add_foreign_key "audit_logs", "users", column: "actor_real_id"
  add_foreign_key "invitations", "organizations"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "mfa_enrollments", "users"
  add_foreign_key "organizations", "accounts"
  add_foreign_key "password_reset_tokens", "users"
  add_foreign_key "recovery_codes", "users"
  add_foreign_key "role_assignments", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "users", "accounts"
end
