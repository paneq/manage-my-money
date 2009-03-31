class AddLevelColumnToSystemCategory < ActiveRecord::Migration
  def self.up
    change_table(:system_categories) do |t|
      t.integer :cached_level
      t.string :name_with_path
    end

    require File.dirname(__FILE__) + '/../fixtures/system_categories_populator.rb'
    SystemCategoriesPopulator.cache_data

  end

  def self.down
    remove_column(:system_categories, :cached_level, :name_with_path)
  end
end
