class AddDefaultCurrencyColumn < ActiveRecord::Migration
  def self.up
    add_column :users, :default_currency_id, :integer, :null => false, :default => get_default_currency.id
  end

  def self.down
    remove_column :users, :default_currency_id
  end

  private
  def self.get_default_currency
    Currency.find :first, :conditions => {:long_symbol => 'PLN'}
  end

end
