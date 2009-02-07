class AddInvertSaldoForAssetsColumnForUser < ActiveRecord::Migration
  def self.up
    add_column :users, :invert_saldo_for_assets, :boolean, :null => false, :default => true
  end

  def self.down
    remove_column :users, :invert_saldo_for_assets
  end
end
