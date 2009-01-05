# == Schema Information
# Schema version: 20090104123107
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
#  user_id              :integer       
#  created_at           :datetime      
#  updated_at           :datetime      
#  share_type_int       :integer       default(0)
#  depth                :integer       default(0)
#  max_categories_count :integer       default(0)
#  category_id          :integer       
#  period_division_int  :integer       default(2)
#

class ValueReport < MultipleCategoryReport
  define_enum :period_division, [:day, :week, :none] #TODO
  validates_inclusion_of :report_view_type, :in => [:bar, :linear]

  def value_report?
    true
  end

end
