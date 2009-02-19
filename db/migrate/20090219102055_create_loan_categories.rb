class CreateLoanCategories < ActiveRecord::Migration

  def self.up
    change_table(:categories) do |t|
      t.string :type
      t.string :email, :null => true
      t.text :bankinfo, :null => true
    end
  end


  def self.down
    change_table(:categories) do |t|
      t.remove :type, :email, :bankinfo
    end
  end

end
