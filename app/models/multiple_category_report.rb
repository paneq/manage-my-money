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

class MultipleCategoryReport < Report
  has_many :category_report_options, :foreign_key => :report_id
  has_many :categories, :through => :category_report_options

  validate :has_at_least_one_category?

  def has_at_least_one_category?
     unless categories != nil && categories.size > 0
       errors.add(:categories, "Should have at least one category")
     end
  end

end
