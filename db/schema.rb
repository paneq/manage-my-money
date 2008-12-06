# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20081206132610) do

  create_table "categories", :force => true do |t|
    t.string  "name",        :null => false
    t.string  "description"
    t.integer "_type_"
    t.integer "category_id"
    t.integer "user_id"
  end

  create_table "currencies", :force => true do |t|
    t.string  "symbol",      :null => false
    t.string  "long_symbol", :null => false
    t.string  "name",        :null => false
    t.string  "long_name",   :null => false
    t.integer "user_id"
  end

  create_table "exchanges", :force => true do |t|
    t.integer "currency_a",    :null => false
    t.integer "currency_b",    :null => false
    t.float   "left_to_right", :null => false
    t.float   "right_to_left", :null => false
    t.date    "day",           :null => false
    t.integer "user_id"
  end

  create_table "goals", :force => true do |t|
    t.string   "description"
    t.boolean  "include_subcategories"
    t.integer  "period_type_int"
    t.integer  "goal_type_int"
    t.integer  "goal_completion_condition_int"
    t.float    "value"
    t.integer  "category_id",                   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "transfer_items", :force => true do |t|
    t.text    "description",                :null => false
    t.integer "value",                      :null => false
    t.integer "transfer_id",                :null => false
    t.integer "category_id",                :null => false
    t.integer "currency_id", :default => 3, :null => false
  end

  create_table "transfers", :force => true do |t|
    t.text    "description", :null => false
    t.date    "day",         :null => false
    t.integer "user_id",     :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "login",                                        :limit => 40
    t.string   "name",                                         :limit => 100, :default => ""
    t.string   "email",                                        :limit => 100
    t.string   "crypted_password",                             :limit => 40
    t.string   "salt",                                         :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",                               :limit => 40
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",                              :limit => 40
    t.datetime "activated_at"
    t.boolean  "active",                                                      :default => false, :null => false
    t.integer  "transaction_amount_limit_type",                               :default => 0,     :null => false
    t.integer  "transaction_amount_limit_value"
    t.boolean  "include_transactions_from_subcategories",                     :default => false, :null => false
    t.integer  "multi_currency_balance_calculating_algorithm",                :default => 0,     :null => false
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

end
