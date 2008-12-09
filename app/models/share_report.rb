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

class ShareReport < Report
  belongs_to :category
  define_enum :share_type, [:percentage, :value]

  validates_presence_of :report_view_type, :share_type, :category
  validates_inclusion_of :report_view_type, :in => [:pie, :bar]

end
