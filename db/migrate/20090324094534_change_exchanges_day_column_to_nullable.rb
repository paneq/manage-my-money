class ChangeExchangesDayColumnToNullable < ActiveRecord::Migration
  def self.up
    change_column(:exchanges, :day, :date, :null => true)
  end

  def self.down
    change_column(:exchanges, :day, :date, :null => false)
  end
end
