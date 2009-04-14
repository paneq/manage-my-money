# == Schema Information
# Schema version: 20090414090944
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

class ValueReport < MultipleCategoryReport
  define_enum :period_division, [:day, :week, :month, :quarter, :year, :none]
  validates_inclusion_of :report_view_type, :in => [:bar, :linear]

  def value_report?
    true
  end

  #return [{:category => a, :dates => [[date1, date2], ..], :values => [1,2,4], ::with_subcategories => true}, ...]
  def calculate_values


    dates = Date.split_period(self.period_division, self.period_start, self.period_end)

    categories_to_compute_only = self.category_report_options.find_all{|option| option.inclusion_type == :category_only || option.inclusion_type == :both}.map(&:category)
    categories_to_compute_with_sucategories = self.category_report_options.find_all{|option| option.inclusion_type == :category_and_subcategories || option.inclusion_type == :both}.map(&:category)

    result = []
    
    unless categories_to_compute_only.blank?
      Category.compute(:default, self.user, categories_to_compute_only, false, dates).each do |category, values|
        result << {:category => category, :values => values, :dates => dates, :with_subcategories => false}
      end
    end

    unless categories_to_compute_with_sucategories.blank?
      Category.compute(:default, self.user, categories_to_compute_with_sucategories, true, dates).each do |category, values|
        result << {:category => category, :values => values, :dates => dates, :with_subcategories => true}
      end
    end

    return result
  end

end
