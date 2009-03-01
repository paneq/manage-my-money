class CyclicGoals < ActiveRecord::Migration
  def self.up
    change_table(:goals) do |t|
      t.boolean :is_cyclic
      t.boolean :is_finished
      t.integer :cycle_group
      t.integer :user_id, :null => false
    end
  end

  def self.down
    change_table(:goals) do |t|
      t.remove :is_cyclic, :cycle_group, :is_finished, :user_id
    end
  end
end
