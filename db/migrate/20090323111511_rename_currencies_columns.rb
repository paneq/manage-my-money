class RenameCurrenciesColumns < ActiveRecord::Migration
  def self.up
    rename_column(:exchanges, :currency_a, :left_currency_id)
    rename_column(:exchanges, :currency_b, :right_currency_id)
  end

  def self.down
    rename_column(:exchanges, :left_currency_id, :currency_a)
    rename_column(:exchanges, :right_currency_id, :currency_b)
  end
end
