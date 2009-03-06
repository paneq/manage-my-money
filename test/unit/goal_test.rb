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


  def test_set_cycle_group_on_save
    g = create_goal(false)
    g.period_type = :NEXT_WEEK
    g.period_start = '01.01.2008'.to_date
    g.period_end = '07.01.2008'.to_date
    g.is_cyclic = true
    g.save!
    assert_equal g.id, g.cycle_group
    g.is_cyclic = false
    g.save!
    assert_equal nil, g.cycle_group

    g2 = create_goal(false)
    g2.is_cyclic = false
    g2.save!
    assert_equal nil, g2.cycle_group
    g2.period_type = :NEXT_WEEK
    g2.period_start = '01.01.2008'.to_date
    g2.period_end = '07.01.2008'.to_date
    g2.is_cyclic = true
    g2.save!
    assert_equal g2.id, g2.cycle_group
  end
  

  private
  


end
