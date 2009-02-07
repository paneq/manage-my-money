class RemoveActiveColumn < ActiveRecord::Migration
  def self.up
    remove_column :users, :active
  end

  def self.down
    add_column :users, :active, :boolean, :null => false, :default => false
    User.find(:all).each {|u| u.active = true; u.save }
  end
end
