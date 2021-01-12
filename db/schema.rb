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

ActiveRecord::Schema.define(version: 2021_01_07_205415) do

  create_table "absolute_ids", force: :cascade do |t|
    t.string "value"
    t.integer "integer"
    t.integer "check_digit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "prefix"
    t.string "initial_value"
    t.string "repository_id"
    t.string "resource_id"
    t.string "archivesspace_resource_id"
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

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
