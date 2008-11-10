class CreateGoals < ActiveRecord::Migration
  def self.up
    create_table :goals do |t|
      t.string :description
      t.boolean :include_subcategories
      t.integer :period_type
      t.integer :goal_type
      t.integer :goal_completion_condition

      t.timestamps
    end
  end

  def self.down
    drop_table :goals
  end
end
