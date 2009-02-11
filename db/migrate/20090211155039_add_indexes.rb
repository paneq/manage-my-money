class AddIndexes < ActiveRecord::Migration
  def self.up
    add_index :users, :id, :unique => true
    
    add_index :categories, [:id, :user_id, :category_type_int], :uniqe => true
    add_index :categories, [:lft, :rgt]
    add_index :categories, :rgt
    
    add_index :transfers, [:id, :user_id], :uniqe => true
    add_index :transfers, :day
    add_index :transfers, :user_id
    
    add_index :transfer_items, :id, :uniqe => true
    add_index :transfer_items, :category_id
    add_index :transfer_items, :transfer_id
    add_index :transfer_items, :currency_id

    add_index :currencies, [:id, :user_id], :uniqe => true
    
    add_index :exchanges, :day
    
    add_index :goals, :id
    add_index :goals, :category_id
    
    add_index :reports, :id
    add_index :reports, :user_id
    add_index :reports, :category_id

    add_index :category_report_options, [:report_id, :category_id]
  end

  def self.down
    remove_index :users, :column => :id
 
    remove_index :categories, :column => [:id, :user_id, :category_type_int]
    remove_index :categories, [:lft, :rgt]
    remove_index :categories, :rgt
 
    remove_index :transfers, :column => [:id, :user_id]
    remove_index :transfers, :column => :day
    remove_index :transfers, :column => :user_id
 
    remove_index :transfer_items, :column => :id
    remove_index :transfer_items, :column => :category_id
    remove_index :transfer_items, :column => :transfer_id
    remove_index :transfer_items, :column => :currency_id

    remove_index :currencies, :column => [:id, :user_id]
 
    remove_index :exchanges, :column => :day
 
    remove_index :goals, :column => :id
    remove_index :goals, :column => :category_id
 
    remove_index :reports, :column => :id
    remove_index :reports, :column => :user_id
    remove_index :reports, :column => :category_id

    remove_index :category_report_options, :column => [:report_id, :category_id]
  end
end
