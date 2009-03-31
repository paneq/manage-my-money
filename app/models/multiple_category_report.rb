# == Schema Information
# Schema version: 20090330164910
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

class MultipleCategoryReport < Report
  has_many :category_report_options, :foreign_key => :report_id, :dependent => :destroy, :include => :category, :order => 'categories.category_type_int, categories.lft'
  has_many :categories, :through => :category_report_options# 

  validate :has_at_least_one_category?

  validates_associated :category_report_options

  def has_at_least_one_category?
     unless category_report_options != nil && category_report_options.size > 0
       errors.add_to_base(:should_have_at_least_one_category)
     end
  end

  def new_category_report_options=(category_report_options_attr)
    category_report_options_attr.each do |attributes|
      if attributes[:inclusion_type] != 'none'
        category = Category.find(attributes[:category_id])
        category_report_options.build({:inclusion_type => attributes[:inclusion_type], :category => category})
      else 
        category_report_options.delete_if {|item| item.category_id == attributes[:category_id]}
      end
    end
  end

  after_update :save_options

  def existing_category_report_options=(category_report_options_attr)
    category_report_options.reject(&:new_record?).each do |option|
      attributes = category_report_options_attr[option.id.to_s]
      if attributes && attributes[:inclusion_type] != 'none'
        option.attributes = attributes
      else
        category_report_options.delete(option)
      end
    end
  end

  def save_options
    category_report_options.each do |option|
      option.save(false)
    end
  end



  #dla kazdej category na liscie categories i dla ktorej nie ma category_report_option
  #tworzy category_report_option i ustawia mu inclusion_type na :none
  #
  def prepare_category_report_options(given_categories)
    given_categories.each do |cat|
      unless categories.include? cat
        category_report_options << CategoryReportOption.new({:category => cat, :inclusion_type => :none})
      end
   end
  end


end
