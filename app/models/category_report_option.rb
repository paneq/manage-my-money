# == Schema Information
# Schema version: 20090306160304
#
# Table name: category_report_options
#
#  id                 :integer       not null, primary key
#  inclusion_type_int :integer       default(0), not null
#  report_id          :integer       not null
#  category_id        :integer       not null
#  created_at         :datetime      
#  updated_at         :datetime      
#

class CategoryReportOption < ActiveRecord::Base
  extend HashEnums
  belongs_to :multiple_category_report, :foreign_key => :report_id
  belongs_to :category, :foreign_key => :category_id
  define_enum :inclusion_type, [:category_only, :category_and_subcategories, :both, :none]
end
