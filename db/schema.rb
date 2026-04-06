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

ActiveRecord::Schema[8.1].define(version: 2026_04_06_173307) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "status_types", ["success", "failure"]

  create_table "data_sets", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", precision: nil, null: false
    t.string "data"
    t.string "data_file"
    t.datetime "report_time", precision: nil
    t.boolean "status", default: true
    t.datetime "updated_at", precision: nil, null: false
    t.index ["category"], name: "index_data_sets_on_category"
  end

  create_table "flipflop_features", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false, null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
  end

  create_table "peoplesoft_transactions", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "transaction_id"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "recent_job_statuses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "job", null: false
    t.enum "status", null: false, enum_type: "status_types"
    t.datetime "updated_at", null: false
    t.index ["job"], name: "index_recent_job_statuses_on_job", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "email"
    t.string "token"
    t.datetime "updated_at", precision: nil, null: false
  end
end
