# == Schema Information
# Schema version: 20090226180602
#
# Table name: reports
#
#  id                          :integer       not null, primary key
#  type                        :string(255)   
#  name                        :string(255)   not null
#  period_type_int             :integer       not null
#  period_start                :date          
#  period_end                  :date          
#  report_view_type_int        :integer       not null
#  is_predefined               :boolean       not null
#  user_id                     :integer       
#  created_at                  :datetime      
#  updated_at                  :datetime      
#  depth                       :integer       default(0)
#  max_categories_values_count :integer       default(0)
#  category_id                 :integer       
#  period_division_int         :integer       default(5)
#  temporary                   :boolean       not null
#  relative_period             :boolean       not null
#

class ShareReport < Report
  belongs_to :category

  validates_presence_of :report_view_type, :category
  validates_inclusion_of :report_view_type, :in => [:pie, :bar]

  validates_numericality_of  :max_categories_values_count, :only_integer => true, :greater_than_or_equal_to => 1
  validates_numericality_of  :depth, :only_integer => true, :greater_than_or_equal_to => -1, :less_than_or_equal_to => 6

  def share_report?
    true
  end

end
