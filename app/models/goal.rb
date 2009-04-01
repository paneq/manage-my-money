# == Schema Information
# Schema version: 20090330164910
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
#  is_cyclic                     :boolean       not null
#  is_finished                   :boolean       not null
#  cycle_group                   :integer       
#  user_id                       :integer       not null
#

class Goal < ActiveRecord::Base
  include Periodable
  extend HashEnums
  belongs_to :category
  belongs_to :currency
  belongs_to :user


  define_enum :period_type, [:SELECTED] + Date::RECOGNIZED_PERIODS
  define_enum :goal_type, {:percent => 0, :value => 1}
  define_enum :goal_completion_condition, {:at_least => 0, :at_most => 1}

  validates_presence_of :description,
    :value,
    :user,
    :category,
    :goal_type_and_currency,
    :period_type,
    :goal_completion_condition,
    :period_start,
    :period_end

  #  validates_presence_of :currency, :if => :goal_type_value
  validates_numericality_of :value


  validate :validate_goal_type_with_category
  validate :validate_period_type_with_is_cyclic


  def goal_type_value
    goal_type == :value
  end

  def validate_goal_type_with_category
    if (!category.nil?) && goal_type == :percent && category.is_top?
      errors.add_to_base(:wrong_parent_category)
    end 
  end

  def validate_period_type_with_is_cyclic
    if period_type == :SELECTED && is_cyclic
      errors.add_to_base(:period_could_not_be_cyclic)
    end
  end

  def after_save
    if is_cyclic && cycle_group.nil?
      update_attribute :cycle_group, id
    elsif !is_cyclic && !cycle_group.nil?
      update_attribute :cycle_group, nil
    end
  end

  def goal_type_and_currency
    if self.goal_type == :percent
      'percent'
    else
      return nil if self.currency.nil?
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
      category.percent_of_parent_category(period_start, period_end, include_subcategories)
    else
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
    Goal.find(:all, :order => ['period_end'], :conditions => ['user_id = ? AND cycle_group = ?', self.user.id, self.cycle_group])
  end

  
  def create_next_goal_in_cycle
    throw "Period type mismatch: #{period_type}" if period_type == :SELECTED
    throw 'Goal is not cyclic' unless is_cyclic
    new_goal = self.clone
    new_goal.period_start = self.period_end + 1 #self.period_start.shift(Date::period_category(period_type))
    new_goal.period_end = new_goal.period_start.shift(Date::period_category(period_type))
    same_goal = Goal.first :conditions => ['period_start = ? AND period_end = ? AND cycle_group = ?', new_goal.period_start, new_goal.period_end, cycle_group]
    throw 'There is already goal in database' unless same_goal.nil?
    return new_goal
  end


  def next_goal_in_cycle
    if is_cyclic
      Goal.first :conditions => ['period_start = ? AND cycle_group = ?', period_end + 1, cycle_group]
    else
      nil
    end
  end


  def self.find_cyclic_goals_to_copy
    #zalozenia
    #is_cyclic == true
    #period_end == today #dyskusyjne :)
    #is_finished == false
    Goal.all :conditions => ['is_cyclic = ? AND period_end = ? AND is_finished = ?', true, Date.today, false]
  end


  def self.find_past(user)
    sql = <<-SQL
    (
      select
        goals.*
      from
        goals,
        (
          select
            cycle_group,
            max(period_end) as max_end
          from
            goals
          where
            period_end < ?
          group by
            cycle_group
        ) as goals_groups
      where
        goals.cycle_group = goals_groups.cycle_group
        AND goals.period_end = goals_groups.max_end
        AND user_id = ?

     union

      select
        *
      from
        goals
      where
        (period_end < ? OR is_finished = ?)
        AND is_cyclic = ?
        AND user_id = ?
     )
      order by period_end
    SQL

   find_by_sql [sql, Date.today, user.id, Date.today, true, false, user.id ]

  end


  def self.find_actual(user)
    all :conditions => ['period_end >= ? AND is_finished = ? AND user_id = ?', Date.today, false, user.id], :order => 'period_end'
  end





end

