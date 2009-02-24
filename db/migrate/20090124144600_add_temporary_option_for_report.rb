class AddTemporaryOptionForReport < ActiveRecord::Migration
  def self.up
    add_column :reports, :temporary, :boolean, :null => false, :default => '0'
  end

  def self.down
    remove_column :reports, :temporary
  end
end
