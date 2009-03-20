class AddColumnsToSystemCategories < ActiveRecord::Migration
  def self.up
    change_table(:system_categories) do |t|
      t.string :description
      t.integer :category_type_int #, :null => false
    end
  end

  def self.down
    remove_column(:system_categories, :description, :category_type_int)
  end
end
