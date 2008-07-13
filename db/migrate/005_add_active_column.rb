class AddActiveColumn < ActiveRecord::Migration
  def self.up
    add_column :users, :active, :boolean, :null => false, :default => false
    User.find(:all).each {|u| u.active = true; u.save }

  end

  def self.down
    remove_column :users, :active
  end
end
