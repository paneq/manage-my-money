class ChangeExchangesForeginKeysColumns < ActiveRecord::Migration

  def self.up
    change_column :exchanges, :currency_a, :integer, :null => false
    change_column :exchanges, :currency_b, :integer, :null => false
    change_column :exchanges, :left_to_right, :decimal, :null => false, :precision => 8, :scale => 4
    change_column :exchanges, :right_to_left, :decimal, :null => false, :precision => 8, :scale => 4
  end

  def self.down
    change_column :exchanges, :currency_a, :decimal, :null => false, :precision => 8, :scale => 4
    change_column :exchanges, :currency_b, :decimal, :null => false, :precision => 8, :scale => 4
    change_column :exchanges, :left_to_right, :float, :null => false
    change_column :exchanges, :right_to_left, :float, :null => false
  end
  
end
