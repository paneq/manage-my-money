# == Schema Information
# Schema version: 20090201170116
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
#  period_division_int  :integer       default(5)
#  temporary            :boolean       not null
#

class Report < ActiveRecord::Base
  extend HashEnums
  define_enum :period_type, [:day, :week, :month, :quarter, :year, :custom]
  define_enum :report_view_type, [:pie, :linear, :text, :bar]

  belongs_to :user

  validates_presence_of :period_start, :period_end, :if => :period_type_custom?
  validates_inclusion_of :period_type, :in => Report.PERIOD_TYPES.keys
  validates_presence_of :name

  #used for conditional validation
  def period_type_custom?
    period_type == :custom
  end

  def share_report?
    false
  end

  def flow_report?
    false
  end

  def value_report?
    false
  end

  def type_str
    read_attribute :type
  end

  def self.sum_flow_values(values)
    if !values.empty? && values.size > 0
      values.inject(Money.new) do |mem, i|
        mem.add(i[:values])
      end
    else
      Money.new
    end
  end


  
end
