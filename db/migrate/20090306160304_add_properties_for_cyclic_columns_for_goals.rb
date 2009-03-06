class AddPropertiesForCyclicColumnsForGoals < ActiveRecord::Migration
  def self.up
    change_column :goals, :is_cyclic, :boolean, :null => false, :default => false
    change_column :goals, :is_finished, :boolean, :null => false, :default => false
  end

  def self.down
    change_column :goals, :is_cyclic, :boolean, :null => true
    change_column :goals, :is_finished, :boolean, :null => true
  end
end
