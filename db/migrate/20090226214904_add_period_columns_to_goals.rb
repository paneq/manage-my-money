class AddPeriodColumnsToGoals < ActiveRecord::Migration
  def self.up
    change_table(:goals) do |t|
      t.date :period_start
      t.date :period_end
    end
  end

  def self.down
    change_table(:goals) do |t|
      t.remove :period_start, :period_end
    end
  end
end
