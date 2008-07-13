class CreateCategories < ActiveRecord::Migration
  def self.up
    create_table :categories do |t|
		t.column :name, :string, :null => false
		t.column :description, :string
		t.column	:_type_, :integer#, :null => false
		t.column :category_id, :integer#, :null => false
		t.column :user_id, :integer#, :null => false
    end
  end

  def self.down
    drop_table :categories
  end
end
