class SetTypeOfExistingCategories < ActiveRecord::Migration
  def self.up
    Category.update_all(" type = 'Category' ")
  end

  def self.down
    Category.update_all(" type = NULL ")
  end
end
