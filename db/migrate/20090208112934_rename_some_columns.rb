class RenameSomeColumns < ActiveRecord::Migration
  def self.up
    rename_column(:users, :invert_saldo_for_assets, :invert_saldo_for_income)
    rename_column(:reports, :max_categories_count, :max_categories_values_count)
  end

  def self.down
    rename_column(:reports, :max_categories_values_count, :max_categories_count)
    rename_column(:users, :invert_saldo_for_income, :invert_saldo_for_assets)
  end
end
