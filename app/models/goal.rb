# == Schema Information
# Schema version: 20090301162726
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
#  is_cyclic                     :boolean       
#  is_finished                   :boolean       
#  cycle_group                   :integer       
#  user_id                       :integer       not null
#

#require 'hash_enums'
class Goal < ActiveRecord::Base
  extend HashEnums
  belongs_to :category
  belongs_to :currency
  belongs_to :user
  #has_many :historical_goals


  define_enum :period_type, [:SELECTED] + Date::RECOGNIZED_PERIODS
  define_enum :goal_type, {:percent => 0, :value => 1}
  define_enum :goal_completion_condition, {:at_least => 0, :at_most => 1}

  validates_presence_of :description,
                        :value,
                        :category,
                        :user,
                        :goal_type_and_currency,
                        :period_type,
                        :goal_completion_condition,
                        :period_start,
                        :period_end
  validates_numericality_of :value

  validate :validate_goal_type_with_category
  validate :validate_period_type_with_is_cyclic

  def validate_goal_type_with_category
    if !category.nil? && !goal_type == :percent && category.is_top?
      errors.add(:category, 'Dla danego typu planu wymagane jest aby wybrana kategoria miała nadkategorie')
    end 
  end

  def validate_period_type_with_is_cyclic
    if period_type == :SELECTED && is_cyclic
      errors.add(:period_type, 'Aby móc powtarzać plan musisz wybrać okres z listy')
    end
  end


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

  def after_save
    if is_cyclic && cycle_group.nil?
      update_attribute :cycle_group, id
    elsif !is_cyclic && !cycle_group.nil?
      update_attribute :cycle_group, nil
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
      "% z #{category.parent.name}"
    else
      currency.symbol
    end
  end

  def period_description
    desc = "#{period_start} do #{period_end}"
    desc += " (#{Date::period_category_name(period_type)})" unless period_type == :SELECTED || is_finished
    desc
  end


  def value_description
    prefix = if goal_completion_condition == :at_most
      'max'
    else
      'min'
    end

    "#{prefix} #{value_with_unit}"
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


  def finish
    self.is_finished = true
    self.is_cyclic = false
    self.period_end = Date.today
    save
  end


  def finished?
    self.is_finished || (self.period_end < Date.today)
  end

  def all_goals_in_cycle
    Goal.find(:all, :order => ['period_end'], :conditions => ['cycle_group = ?', self.cycle_group])
  end

  def create_new_goal_in_cycle
    new_goal = self.clone
    self.is_cyclic = false
    new_goal.period_start = self.period_start.shift(Date::period_category(period_type))
    new_goal.period_end = self.period_end.shift(Date::period_category(period_type))


    new_goal
  end



end

