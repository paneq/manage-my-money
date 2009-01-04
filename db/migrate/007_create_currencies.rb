class CreateCurrencies < ActiveRecord::Migration
  def self.up
    create_table :currencies do |t|
      t.column :symbol, :string, :null => false
      t.column :long_symbol, :string, :null => false
      t.column :name, :string, :null => false
      t.column :long_name, :string, :null => false
      t.column :user_id, :integer, :null => true
    end
    self.standard_currencies.each {|c| cur = Currency.new(c); cur.save!}
  end

  def self.down
    drop_table :currencies
  end
  
  def self.standard_currencies
    zl = {
      :symbol => 'zł',
      :long_symbol => 'PLN',
      :name => 'zloty',
      :long_name => 'Polski zloty',
      :user_id => nil
    }
    
    usd = {
      :symbol => '$',
      :long_symbol => 'USD',
      :name => 'dollar',
      :long_name => 'American dollar',
      :user_id => nil
    }
    
    euro = {
      :symbol => '€',
      :long_symbol => 'EUR',
      :name => 'euro',
      :long_name => 'Euro',
      :user_id => nil
    }

    return [zl, usd, euro]
  end
end
