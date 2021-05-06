# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_05_06_183059) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "absolute_id_archival_objects", force: :cascade do |t|
    t.string "uri"
    t.string "json_resource"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "absolute_id_batches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.bigint "absolute_id_session_id"
    t.index ["absolute_id_session_id"], name: "index_absolute_id_batches_on_absolute_id_session_id"
    t.index ["user_id"], name: "index_absolute_id_batches_on_user_id"
  end

  create_table "absolute_id_container_profiles", force: :cascade do |t|
    t.string "uri"
    t.string "json_resource"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "absolute_id_locations", force: :cascade do |t|
    t.string "uri"
    t.string "json_resource"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "absolute_id_repositories", force: :cascade do |t|
    t.string "uri"
    t.string "json_resource"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "absolute_id_resources", force: :cascade do |t|
    t.string "uri"
    t.string "json_resource"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "absolute_id_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_absolute_id_sessions_on_user_id"
  end

  create_table "absolute_id_top_containers", force: :cascade do |t|
    t.string "uri"
    t.string "json_resource"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "absolute_ids", force: :cascade do |t|
    t.string "value"
    t.string "integer"
    t.integer "check_digit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "initial_value"
    t.integer "index"
    t.string "location"
    t.string "container_profile"
    t.string "repository"
    t.string "resource"
    t.string "container"
    t.bigint "absolute_id_batch_id"
    t.string "unencoded_location"
    t.string "unencoded_repository"
    t.string "unencoded_container_profile"
    t.string "unencoded_container"
    t.datetime "synchronized_at"
    t.boolean "synchronizing"
    t.string "synchronize_status"
    t.string "pool_identifier"
    t.index ["absolute_id_batch_id"], name: "index_absolute_ids_on_absolute_id_batch_id"
    t.index ["pool_identifier"], name: "index_absolute_ids_on_pool_identifier"
  end

  create_table "archival_objects_top_containers", id: false, force: :cascade do |t|
    t.bigint "archival_object_id", null: false
    t.bigint "top_container_id", null: false
    t.index ["archival_object_id"], name: "archival_object_id"
    t.index ["top_container_id"], name: "top_container_id"
  end

  create_table "data_sets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "report_time"
    t.string "data"
    t.string "data_file"
    t.string "category"
    t.boolean "status", default: true
    t.index ["category"], name: "index_data_sets_on_category"
  end

  create_table "resources_top_containers", id: false, force: :cascade do |t|
    t.bigint "resource_id", null: false
    t.bigint "top_container_id", null: false
    t.index ["resource_id"], name: "resource_id"
    t.index ["top_container_id"], name: "container_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "absolute_id_batches", "absolute_id_sessions"
  add_foreign_key "absolute_id_batches", "users"
  add_foreign_key "absolute_id_sessions", "users"
  add_foreign_key "absolute_ids", "absolute_id_batches"
end
