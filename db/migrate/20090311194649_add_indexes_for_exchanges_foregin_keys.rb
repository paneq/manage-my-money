class AddIndexesForExchangesForeginKeys < ActiveRecord::Migration
  def self.up
    add_index :exchanges, [:user_id, :currency_a, :currency_b, :day]
  end

  def self.down
    remove_index :exchanges, :column => [:user_id, :currency_a, :currency_b, :day]
  end
end
