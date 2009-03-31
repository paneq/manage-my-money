class AddTimestampsToCategory < ActiveRecord::Migration
  def self.up
    change_table(:categories) do |t|
      t.timestamps
    end
  end

  def self.down
    remove_column(:categories, :created_at, :updated_at)
  end
end
