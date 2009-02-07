class CreateTransfers < ActiveRecord::Migration
  def self.up
    create_table :transfers do |t|
      t.column :description, :text, :null => false
      t.column :day, :date, :null => false
      t.column :user_id, :integer, :null => false
    end
  end

  def self.down
    drop_table :transfers
  end
end
