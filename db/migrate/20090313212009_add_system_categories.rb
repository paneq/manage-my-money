class AddSystemCategories < ActiveRecord::Migration
  def self.up
    create_table :system_categories do |t|
      t.string :name, :null => false

      #awesom nested set
		  t.integer :parent_id
      t.integer :lft
      t.integer :rgt

      t.timestamps
    end

    create_table :categories_system_categories, :id => false do |t|
      t.integer :category_id, :null => false
      t.integer :system_category_id, :null => false
    end
  end

  def self.down
    drop_table :categories_system_categories
    drop_table :system_categories
  end
end
