class AddLoanCategoryBitToCategory < ActiveRecord::Migration
  def self.up
    add_column :categories, :loan_category, :boolean
    remove_column :categories, :type
  end

  def self.down
    add_column :categories, :type, :string
    remove_column :categories, :loan_category
  end
end
