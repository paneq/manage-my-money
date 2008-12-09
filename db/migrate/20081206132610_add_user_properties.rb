class AddUserProperties < ActiveRecord::Migration
  def self.up
    add_column :users, :transaction_amount_limit_type_int, :integer, :null => false, :default => User.TRANSACTION_AMOUNT_LIMIT_TYPES[:actual_month]
    add_column :users, :transaction_amount_limit_value, :integer, :null => true
    add_column :users, :include_transactions_from_subcategories, :boolean, :null => false, :default => false
    add_column :users, :multi_currency_balance_calculating_algorithm_int, :integer, :null => false, :default => User.MULTI_CURRENCY_BALANCE_CALCULATING_ALGORITHMS[:show_all_currencies]
  end

  def self.down
    remove_column :users, :transaction_amount_limit_type_int
    remove_column :users, :transaction_amount_limit_value
    remove_column :users, :include_transactions_from_subcategories
    remove_column :users, :multi_currency_balance_calculating_algorithm_int
  end
end
