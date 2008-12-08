class CreateCategories < ActiveRecord::Migration
  def self.up
    create_table :categories do |t|
		t.string :name, :null => false
		t.string :description
		t.integer :category_type_int #, :null => false
    t.integer :user_id #, :null => false

    #awesom nested set
		t.integer :parent_id
    t.integer :lft
    t.integer :rgt
		
    end
  end

  def self.down
    drop_table :categories
  end
end
