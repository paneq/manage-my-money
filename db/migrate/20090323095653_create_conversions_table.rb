class CreateConversionsTable < ActiveRecord::Migration
  def self.up
    create_table :conversions do |t|
      t.references :exchange, :null => false
      t.references :transfer, :null => false
      t.timestamps
    end

    add_index :conversions, :id, :uniqe => true
    add_index :conversions, [:transfer_id, :exchange_id], :uniqe => true
  end

  def self.down
    remove_index :conversions, :column => :id
    remove_index :conversions, :column => [:transfer_id, :exchange_id]
    drop_table :conversions
  end
end
