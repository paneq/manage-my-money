class CreateReports < ActiveRecord::Migration
  def self.up
    create_table :reports do |t|
      t.string :type

      # common attributes
      t.string :name, :null => false
      t.integer :period_type_int, :null => false
      t.date :period_start
      t.date :period_end
      t.integer :report_view_type_int, :null => false
      t.boolean :is_predefined, :null => false, :default => false
      t.column :user_id, :integer, :null => true

      t.timestamps

      # attributes for type=ShareReport
      t.integer :share_type_int #, :default => ShareReport.SHARE_TYPES[:percentage]
      t.integer :depth, :default => 0
      t.integer :max_categories_count, :default => 0
      t.integer :category_id

      # attributes for type=ValueReport
      t.integer :period_division_int, :default => ValueReport.PERIOD_DIVISIONS[:none]

      # attributes for type=FlowReport
      # none
    end
  end

  def self.down
    drop_table :reports
  end
end
