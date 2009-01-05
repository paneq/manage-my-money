# == Schema Information
# Schema version: 20090104123107
#
# Table name: goals
#
#  id                            :integer       not null, primary key
#  description                   :string(255)   
#  include_subcategories         :boolean       
#  period_type_int               :integer       
#  goal_type_int                 :integer       
#  goal_completion_condition_int :integer       
#  value                         :float         
#  category_id                   :integer       not null
#  created_at                    :datetime      
#  updated_at                    :datetime      
#

#require 'hash_enums'
class Goal < ActiveRecord::Base
  extend HashEnums
  belongs_to :category

  #has_many :historical_goals


  define_enum :period_type, {:infinite => 0,:monthly => 1}
  define_enum :goal_type, {:percent=>0, :value=>1}
  define_enum :goal_completion_condition,{:at_least=>0, :at_most=>1}

  
  #ile procent kategorii nadrzędnej stanowi saldo tej kategorii w okresie zadanym przez Goal
  def percent_of_parent_category
    category.percent_of_parent_category(start_day, end_day)  #TODO do zaimplementowania w catgory
  end

  #mówi czy osiągnieto cel, czy to dobrze czy źle zależy od wartości :goal_completion_condition
  def is_goal_reached

  end

  #ile punktów procentowych zostało do osiągnięcia celu
  def percents_to_reach_goal

  end

  #ile pięniędzy zostało do osiągnięcia celu
  def money_to_reach_goal

  end

  #o ile punktów procentowych przekroczono cel
  def percents_of_goal_exceed

  end

  #o ile pieniędzy przekroczono cel
  def money_of_goal_exceed

  end

  #zwraca różnicę w wykonaniu planu w tym i poprzednim okresie (procentowo lub w wartości)
  def goal_realization_compared_to_last_period

  end


end

