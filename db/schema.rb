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

ActiveRecord::Schema.define(version: 2023_02_09_015157) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "articles", force: :cascade do |t|
    t.string "title"
    t.string "anonce_image"
    t.string "anonce_text"
    t.string "anonce_data"
    t.string "content"
    t.string "mtitle"
    t.string "mdesc"
    t.string "mkeywords"
    t.string "tags"
    t.string "insales_link"
    t.string "article_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "categories", force: :cascade do |t|
    t.bigint "boss_id"
    t.string "name"
    t.string "link"
    t.string "url"
    t.text "category_path"
    t.string "image_from_up"
    t.text "description_from_up"
    t.string "image"
    t.text "description"
    t.text "sdesc"
    t.text "mtitle"
    t.text "mdesc"
    t.text "mkeywords"
    t.boolean "parsing", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "amount"
    t.integer "parent_id"
    t.index ["boss_id"], name: "index_categories_on_boss_id"
  end

  create_table "images", force: :cascade do |t|
    t.string "old_url"
    t.string "new_url"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reviews", force: :cascade do |t|
    t.string "title"
    t.string "text"
    t.string "author"
    t.string "rating"
    t.string "date"
    t.string "date_published"
    t.string "item_reviewed"
    t.bigint "tov_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tov_id"], name: "index_reviews_on_tov_id"
  end

  create_table "tovs", force: :cascade do |t|
    t.string "fid"
    t.string "link"
    t.string "sku"
    t.string "title"
    t.string "sdesc"
    t.string "desc"
    t.string "oldprice"
    t.string "price"
    t.string "pict"
    t.string "quantity"
    t.string "cat"
    t.string "cat1"
    t.string "cat2"
    t.string "cat3"
    t.string "cat4"
    t.string "mtitle"
    t.string "mdesc"
    t.string "mkeyw"
    t.string "p1"
    t.string "p2"
    t.string "p3"
    t.string "p4"
    t.string "photo_var"
    t.string "uid"
    t.string "p4_admin"
    t.string "video"
    t.string "option1"
    t.string "option2"
    t.string "option3"
    t.string "option4"
    t.string "option5"
    t.string "option6"
    t.string "option7"
    t.string "option8"
    t.string "option9"
    t.string "option10"
    t.string "option11"
    t.string "option12"
    t.string "option13"
    t.string "option14"
    t.string "label"
    t.boolean "check"
    t.string "linkins"
    t.string "insid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "reviews", "tovs"
end
