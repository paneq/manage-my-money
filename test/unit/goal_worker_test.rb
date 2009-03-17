require 'test_helper'
require 'bdrb_test_helper'
require 'goal_worker'


class GoalWorkerTest < ActiveSupport::TestCase

  def setup
    @worker = GoalWorker.new
    save_jarek
  end

  #test jesli w bazie nie ma nic
  def test_dont_create_goals_for_empty_table
    goals = Goal.all
    assert_equal 0, goals.size
    @worker.create_goals_for_next_cycle
    goals = Goal.all
    assert_equal 0, goals.size
  end

  #test jesli w bazie sa tylko cele niecylkiczne
  def test_dont_create_goals_for_non_cyclic_goals
    g = create_goal(false)
    g.is_cyclic = false
    g.save!

    g2 = create_goal(false)
    g2.is_cyclic = false
    g2.save!

    goals = Goal.all
    assert_equal 2, goals.size
    @worker.create_goals_for_next_cycle
    goals = Goal.all
    assert_equal 2, goals.size
    assert_goals_equal g, Goal.find(g.id)
    assert_goals_equal g2, Goal.find(g2.id)
  end


  #test jesli w bazie jest cel cylkiczny
  def test_create_goals_for_one_cyclic_goal
    g = create_goal(false)
    g.period_type = :NEXT_WEEK
    g.period_start = '01.01.2008'.to_date
    g.period_end = '07.01.2008'.to_date
    g.is_cyclic = true
    g.save!

    goals = Goal.all 
    assert_equal 1, goals.size

     with_dates('02.01.2007', '01.01.2008', '03.01.2008', '01.05.2008') do
      @worker.create_goals_for_next_cycle
    end

    goals = Goal.all
    assert_equal 1, goals.size

    with_dates('07.01.2008') do
      @worker.create_goals_for_next_cycle
    end
    goals = Goal.all
    assert_equal 2, goals.size
    assert_goals_equal g, Goal.find(g.id)

    g2 = g.next_goal_in_cycle

    assert_not_nil g2
  end



  #test jesli w bazie jest wiele celow cylkicznych i innych
  def test_create_goals_for_many_cyclic_and_non_cyclic_goals
    #should be copyed
    g1 = create_goal(false)
    g1.period_type = :NEXT_YEAR
    g1.period_start = '01.01.2008'.to_date
    g1.period_end = '31.12.2008'.to_date
    g1.is_cyclic = true
    g1.save!

    g2 = create_goal(false)
    g2.period_type = :NEXT_WEEK
    g2.period_start = '01.01.2008'.to_date
    g2.period_end = '07.01.2008'.to_date
    g2.is_cyclic = true
    g2.save!

    #should be copyed
    g3 = create_goal(false)
    g3.period_type = :NEXT_DAY
    g3.period_start = '31.12.2008'.to_date
    g3.period_end = '31.12.2008'.to_date
    g3.is_cyclic = true
    g3.save!

    g4 = create_goal(false)
    g4.period_type = :NEXT_DAY
    g4.period_start = '30.12.2008'.to_date
    g4.period_end = '31.12.2008'.to_date
    g4.is_cyclic = false
    g4.save!

    goals = Goal.all
    assert_equal 4, goals.size

    with_dates('01.01.2007') do
      @worker.create_goals_for_next_cycle
    end

    goals = Goal.all
    assert_equal 4, goals.size

    with_dates('31.12.2008') do
      @worker.create_goals_for_next_cycle
    end
    goals = Goal.all
    assert_equal 6, goals.size
    [g1,g2,g3,g4].each do |g|
      assert_goals_equal g, Goal.find(g.id)
    end

    assert_not_nil g1.next_goal_in_cycle
    assert_nil g2.next_goal_in_cycle
    assert_not_nil g3.next_goal_in_cycle
    assert_nil g4.next_goal_in_cycle
  end

  #test jesli jest cel cykliczny z historia
  def test_create_goals_for_goal_with_history
    g1 = create_goal(false)
    g1.period_type = :NEXT_YEAR
    g1.period_start = '01.01.2008'.to_date
    g1.period_end = '31.12.2008'.to_date
    g1.is_cyclic = true
    g1.save!

    g2 = g1.create_next_goal_in_cycle
    g2.save!
    
    g3 = g2.create_next_goal_in_cycle
    g3.save!
    
    goals = Goal.all
    assert_equal 3, goals.size

    with_dates('31.12.2010') do
      @worker.create_goals_for_next_cycle
    end
    
    goals = Goal.all
    assert_equal 4, goals.size

    assert_not_nil g3.next_goal_in_cycle
  end



  #W bazie jest cel, ale jest juz skopiowany
  def test_dont_create_goals_for_already_exiting_goal_copy
    g1 = create_goal(false)
    g1.period_type = :NEXT_YEAR
    g1.period_start = '01.01.2008'.to_date
    g1.period_end = '31.12.2008'.to_date
    g1.is_cyclic = true
    g1.save!

    g2 = g1.create_next_goal_in_cycle
    g2.save!

    goals = Goal.all
    assert_equal 2, goals.size


    with_dates('31.12.2008') do
      @worker.create_goals_for_next_cycle
    end

    goals = Goal.all
    assert_equal 2, goals.size

    assert_not_nil g1.next_goal_in_cycle
    assert_nil g2.next_goal_in_cycle
  end
end
