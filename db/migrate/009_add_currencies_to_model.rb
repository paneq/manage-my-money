class AddCurrenciesToModel < ActiveRecord::Migration
  def self.up
    def_curr = Currency.find_by_name('euro')
    add_column :transfer_items, :currency_id, :integer, :null => false, :default => def_curr.id
  end

  def self.down
    remove_column :transfer_items, :currency_id
  end
end
