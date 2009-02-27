class AddBankAccountNumberToCategory < ActiveRecord::Migration
  def self.up
    add_column :categories, :bank_account_number, :string
  end

  def self.down
    remove_column :categories, :bank_account_number
  end
end
