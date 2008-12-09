class CreateCategoryReportOptions < ActiveRecord::Migration
  def self.up
    create_table :category_report_options do |t|
      t.integer :inclusion_type_int, :null => false, :default => CategoryReportOption.INCLUSION_TYPES[:category_only]
      t.integer :report_id, :null => false
      t.integer :category_id, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :category_report_options
  end
end
