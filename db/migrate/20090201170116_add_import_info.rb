class AddImportInfo < ActiveRecord::Migration
  def self.up
    add_column :categories, :import_guid, :string, :null => true
    add_column :categories, :imported, :boolean, :null => true, :default => false

    add_column :transfers, :import_guid, :string, :null => true
    add_column :transfer_items, :import_guid, :string, :null => true
  end

  def self.down
    remove_column :transfer_items, :import_guid
    remove_column :transfers, :import_guid
    remove_column :categories, :imported
    remove_column :categories, :import_guid
  end
end
