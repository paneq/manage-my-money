require 'test_helper'

class GoalTest < ActiveSupport::TestCase

  def setup
    save_jarek
  end
  
  def test_create_next_goal_in_cycle
    g = create_goal
    g.period_type = :NEXT_WEEK
    g.period_start = '01.01.2008'.to_date
    g.period_end = '07.01.2008'.to_date
    g.is_cyclic = true

    g.save!
    new_g = g.create_next_goal_in_cycle

    assert_not_nil new_g

    new_g.save!

    assert_equal g.user, new_g.user
    assert_equal g.category, new_g.category
    assert_equal g.period_type, new_g.period_type
    assert_equal '08.01.2008'.to_date, new_g.period_start
    assert_equal '14.01.2008'.to_date, new_g.period_end
    assert_equal g.goal_type_and_currency, new_g.goal_type_and_currency
    assert_equal g.value, new_g.value
    assert_equal g.description, new_g.description
    assert_equal true, g.is_cyclic
    assert_equal true, new_g.is_cyclic
    assert_not_nil g.cycle_group
    assert_equal g.cycle_group, new_g.cycle_group

    assert_raise RuntimeError, NameError do
      g.create_next_goal_in_cycle
    end



  end
  

  private
  def create_goal
    g = Goal.new

    g.category = @jarek.income
    g.period_type = :SELECTED
    g.period_start = Date.today
    g.period_end = Date.today
    g.goal_type_and_currency = 'PLN'
    g.value = 2.2
    g.description = 'Testowy plan'
    g.user = @jarek 

    g.save!
    g
  end


end
