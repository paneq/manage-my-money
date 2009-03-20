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

ActiveRecord::Schema.define(:version => 20090320114536) do

  create_table "bdrb_job_queues", :force => true do |t|
    t.binary   "args"
    t.string   "worker_name"
    t.string   "worker_method"
    t.string   "job_key"
    t.integer  "taken"
    t.integer  "finished"
    t.integer  "timeout"
    t.integer  "priority"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "archived_at"
    t.string   "tag"
    t.string   "submitter_info"
    t.string   "runner_info"
    t.string   "worker_key"
    t.datetime "scheduled_at"
  end

  create_table "categories", :force => true do |t|
    t.string  "name",                                   :null => false
    t.string  "description"
    t.integer "category_type_int"
    t.integer "user_id"
    t.integer "parent_id"
    t.integer "lft"
    t.integer "rgt"
    t.string  "import_guid"
    t.boolean "imported",            :default => false
    t.string  "type"
    t.string  "email"
    t.text    "bankinfo"
    t.string  "bank_account_number"
  end

  add_index "categories", ["category_type_int", "id", "user_id"], :name => "index_categories_on_id_and_user_id_and_category_type_int"
  add_index "categories", ["lft", "rgt"], :name => "index_categories_on_lft_and_rgt"
  add_index "categories", ["rgt"], :name => "index_categories_on_rgt"

  create_table "categories_system_categories", :id => false, :force => true do |t|
    t.integer "category_id",        :null => false
    t.integer "system_category_id", :null => false
  end

  create_table "category_report_options", :force => true do |t|
    t.integer  "inclusion_type_int", :default => 0, :null => false
    t.integer  "report_id",                         :null => false
    t.integer  "category_id",                       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "category_report_options", ["category_id", "report_id"], :name => "index_category_report_options_on_report_id_and_category_id"

  create_table "currencies", :force => true do |t|
    t.string  "symbol",      :null => false
    t.string  "long_symbol", :null => false
    t.string  "name",        :null => false
    t.string  "long_name",   :null => false
    t.integer "user_id"
  end

  add_index "currencies", ["id", "user_id"], :name => "index_currencies_on_id_and_user_id"

  create_table "exchanges", :force => true do |t|
    t.integer "currency_a",                                  :null => false
    t.integer "currency_b",                                  :null => false
    t.decimal "left_to_right", :precision => 8, :scale => 4, :null => false
    t.decimal "right_to_left", :precision => 8, :scale => 4, :null => false
    t.date    "day",                                         :null => false
    t.integer "user_id"
  end

  add_index "exchanges", ["currency_a", "currency_b", "day", "user_id"], :name => "index_exchanges_on_user_id_and_currency_a_and_currency_b_and_da"
  add_index "exchanges", ["day"], :name => "index_exchanges_on_day"

  create_table "goals", :force => true do |t|
    t.string   "description"
    t.boolean  "include_subcategories"
    t.integer  "period_type_int"
    t.integer  "goal_type_int",                 :default => 0
    t.integer  "goal_completion_condition_int", :default => 0
    t.float    "value"
    t.integer  "category_id",                                      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "currency_id"
    t.date     "period_start"
    t.date     "period_end"
    t.boolean  "is_cyclic",                     :default => false, :null => false
    t.boolean  "is_finished",                   :default => false, :null => false
    t.integer  "cycle_group"
    t.integer  "user_id",                                          :null => false
  end

  add_index "goals", ["category_id"], :name => "index_goals_on_category_id"
  add_index "goals", ["id"], :name => "index_goals_on_id"

  create_table "reports", :force => true do |t|
    t.string   "type"
    t.string   "name",                                           :null => false
    t.integer  "period_type_int",                                :null => false
    t.date     "period_start"
    t.date     "period_end"
    t.integer  "report_view_type_int",                           :null => false
    t.boolean  "is_predefined",               :default => false, :null => false
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "depth",                       :default => 0
    t.integer  "max_categories_values_count", :default => 0
    t.integer  "category_id"
    t.integer  "period_division_int",         :default => 5
    t.boolean  "temporary",                   :default => false, :null => false
    t.boolean  "relative_period",             :default => false, :null => false
  end

  add_index "reports", ["category_id"], :name => "index_reports_on_category_id"
  add_index "reports", ["id"], :name => "index_reports_on_id"
  add_index "reports", ["user_id"], :name => "index_reports_on_user_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "system_categories", :force => true do |t|
    t.string   "name",              :null => false
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description"
    t.integer  "category_type_int"
  end

  create_table "transfer_items", :force => true do |t|
    t.text    "description",                                               :null => false
    t.decimal "value",       :precision => 12, :scale => 2,                :null => false
    t.integer "transfer_id",                                               :null => false
    t.integer "category_id",                                               :null => false
    t.integer "currency_id",                                :default => 3, :null => false
    t.string  "import_guid"
  end

  add_index "transfer_items", ["category_id"], :name => "index_transfer_items_on_category_id"
  add_index "transfer_items", ["currency_id"], :name => "index_transfer_items_on_currency_id"
  add_index "transfer_items", ["id"], :name => "index_transfer_items_on_id"
  add_index "transfer_items", ["transfer_id"], :name => "index_transfer_items_on_transfer_id"

  create_table "transfers", :force => true do |t|
    t.text    "description", :null => false
    t.date    "day",         :null => false
    t.integer "user_id",     :null => false
    t.string  "import_guid"
  end

  add_index "transfers", ["day"], :name => "index_transfers_on_day"
  add_index "transfers", ["id", "user_id"], :name => "index_transfers_on_id_and_user_id"
  add_index "transfers", ["user_id"], :name => "index_transfers_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "login",                                            :limit => 40
    t.string   "name",                                             :limit => 100, :default => ""
    t.string   "email",                                            :limit => 100
    t.string   "crypted_password",                                 :limit => 40
    t.string   "salt",                                             :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",                                   :limit => 40
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",                                  :limit => 40
    t.datetime "activated_at"
    t.integer  "transaction_amount_limit_type_int",                               :default => 2,     :null => false
    t.integer  "transaction_amount_limit_value"
    t.boolean  "include_transactions_from_subcategories",                         :default => false, :null => false
    t.integer  "multi_currency_balance_calculating_algorithm_int",                :default => 0,     :null => false
    t.integer  "default_currency_id",                                             :default => 1,     :null => false
    t.boolean  "invert_saldo_for_income",                                         :default => true,  :null => false
  end

  add_index "users", ["id"], :name => "index_users_on_id", :unique => true
  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

end
