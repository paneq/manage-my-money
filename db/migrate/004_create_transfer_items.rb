class CreateTransferItems < ActiveRecord::Migration
  def self.up
    create_table :transfer_items do |t|
		t.column :description, :text, :null => false
		t.column :gender, :boolean, :null => false
		t.column :value, :integer, :null => false
		t.column :transfer_id, :integer, :null => false
		t.column :category_id, :integer, :null => false
    end
  end

  def self.down
    drop_table :transfer_items
  end
end
