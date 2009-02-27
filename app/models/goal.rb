# == Schema Information
# Schema version: 20090227165910
#
# Table name: goals
#
#  id                            :integer       not null, primary key
#  description                   :string(255)   
#  include_subcategories         :boolean       
#  period_type_int               :integer       
#  goal_type_int                 :integer       default(0)
#  goal_completion_condition_int :integer       default(0)
#  value                         :float         
#  category_id                   :integer       not null
#  created_at                    :datetime      
#  updated_at                    :datetime      
#  currency_id                   :integer       
#  period_start                  :date          
#  period_end                    :date          
#

#require 'hash_enums'
class Goal < ActiveRecord::Base
  extend HashEnums
  belongs_to :category
  belongs_to :currency

  #has_many :historical_goals


  define_enum :period_type, [:SELECTED] + Date::RECOGNIZED_PERIODS
  define_enum :goal_type, {:percent => 0, :value => 1}
  define_enum :goal_completion_condition, {:at_least => 0, :at_most => 1}

  validates_presence_of :description, :value
  validates_numericality_of :value


  def goal_type_and_currency
    if self.goal_type == :percent
      'percent'
    else
      self.currency.long_symbol
    end
  end

  def goal_type_and_currency=(val)
    if val == 'percent'
      self.goal_type = :percent
      self.currency = nil
    else
      self.goal_type = :value
      self.currency = Currency.find_by_long_symbol(val)
    end
  end



  def actual_value
    if goal_type == :percent
      #calculate_percent
      category.percent_of_parent_category(period_start, period_end, include_subcategories)
    else
      #calculate_money
      money = category.saldo_for_period_new(period_start, period_end, :show_all_currencies, include_subcategories)
      money.value(currency)
    end
  end


  def value_with_unit
    "#{value}#{unit}"
  end

  def actual_value_with_unit
    "#{actual_value}#{unit}"
  end


  def unit
    @unit ||= if goal_type == :percent
      '%'
    else
      currency.symbol
    end
  end

  def period_description
    "#{period_start} do #{period_end} (#{Date::period_category_name(period_type)})"
  end


#  #ile procent kategorii nadrzędnej stanowi saldo tej kategorii w okresie zadanym przez Goal
#  def percent_of_parent_category
#    category.percent_of_parent_category(start_day, end_day)  #TODO do zaimplementowania w catgory
#  end
#
#  #mówi czy osiągnieto cel, czy to dobrze czy źle zależy od wartości :goal_completion_condition
#  def is_goal_reached
#
#  end
#
#  #ile punktów procentowych zostało do osiągnięcia celu
#  def percents_to_reach_goal
#
#  end
#
#  #ile pięniędzy zostało do osiągnięcia celu
#  def money_to_reach_goal
#
#  end
#
#  #o ile punktów procentowych przekroczono cel
#  def percents_of_goal_exceed
#
#  end
#
#  #o ile pieniędzy przekroczono cel
#  def money_of_goal_exceed
#
#  end
#
#  #zwraca różnicę w wykonaniu planu w tym i poprzednim okresie (procentowo lub w wartości)
#  def goal_realization_compared_to_last_period
#
#  end


  def positive?
    if goal_completion_condition == :at_most
      actual_value <= value
    else
      actual_value >= value
    end
  end

end

