class AddCurrencyColumnToGoals < ActiveRecord::Migration
  def self.up
    add_column :goals, :currency_id, :integer, :null => true
  end

  def self.down
    remove_column :goals, :currency_id
  end
end
