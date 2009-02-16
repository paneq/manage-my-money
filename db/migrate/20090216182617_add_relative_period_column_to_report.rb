class AddRelativePeriodColumnToReport < ActiveRecord::Migration
  def self.up
    add_column :reports, :relative_period, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :reports, :relative_period
  end
end
