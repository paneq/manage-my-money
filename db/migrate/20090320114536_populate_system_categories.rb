class PopulateSystemCategories < ActiveRecord::Migration
  def self.up
    require File.dirname(__FILE__) + '/../fixtures/system_categories_populator.rb'
    SystemCategoriesPopulator.populate
  end

  def self.down
    SystemCategory.delete_all
  end
end
