class CreateExchanges < ActiveRecord::Migration
  def self.up
    create_table :exchanges do |t|
      t.column :currency_a, :integer, :null => false
      t.column :currency_b, :integer, :null => false
      t.column :left_to_right, :float, :null => false
      t.column :right_to_left, :float, :null => false
      t.column :day, :date, :null => false
      t.column :user_id, :integer, :null => true
    end
  end

  def self.down
    drop_table :exchanges
  end
end
