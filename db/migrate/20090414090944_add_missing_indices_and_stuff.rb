class AddMissingIndicesAndStuff < ActiveRecord::Migration
  def self.up
    add_index :categories_system_categories, [:category_id, :system_category_id]
    add_index :system_categories, :id,  :unique => true
    remove_column :reports, :is_predefined
  end

  def self.down
    add_column :reports, :is_predefined, :boolean, :null => false, :default => false
    remove_index :system_categories, :id
    remove_index :categories_system_categories, [:category_id, :system_category_id]
  end
end
