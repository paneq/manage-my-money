class CreateGoals < ActiveRecord::Migration
  def self.up
    create_table :goals do |t|
      t.string :description
      t.boolean :include_subcategories
      t.integer :period_type_int
      t.integer :goal_type_int
      t.integer :goal_completion_condition_int
      t.integer :category_id, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :goals
  end
end
