class DeleteShareTypeColumnFromReport < ActiveRecord::Migration
  def self.up
    remove_column :reports, :share_type_int
  end

  def self.down
    add_column :reports, :share_type_int, :integer
  end
end
