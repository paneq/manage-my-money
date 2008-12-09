# == Schema Information
# Schema version: 20081208215053
#
# Table name: reports
#
#  id                   :integer       not null, primary key
#  type                 :string(255)   
#  name                 :string(255)   not null
#  period_type_int      :integer       not null
#  period_start         :date          
#  period_end           :date          
#  report_view_type_int :integer       not null
#  is_predefined        :boolean       not null
#  created_at           :datetime      
#  updated_at           :datetime      
#  share_type_int       :integer       default(0)
#  depth                :integer       default(0)
#  max_categories_count :integer       default(0)
#  category_id          :integer       
#  period_division_int  :integer       default(2)
#

class Report < ActiveRecord::Base
  extend HashEnums
  define_enum :period_type, [:week, :day, :custom] #TODO
  define_enum :report_view_type, [:pie, :linear, :text, :bar]

  belongs_to :user

  validates_presence_of :period_start, :period_end, :if => :period_type_custom?
  validates_inclusion_of :period_type, :in => Report.PERIOD_TYPES.keys
  validates_presence_of :name

  #used for conditional validation
  def period_type_custom?
    period_type == :custom
  end

end
