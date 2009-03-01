require 'test_helper'

class GoalTest < ActiveSupport::TestCase

  def setup
    save_jarek
  end
  
  def test_create_new_goal_in_cycle
    create_goal
  end
  

  private
  def create_goal
    @g = Goal.new

    @g.category = @jarek.income
    @g.period_type = :SELECTED
    @g.period_start = Date.today
    @g.period_end = Date.today
    @g.value = 2.2
    @g.description = 'Testowy plan'
    @g.user = @jarek 

    @g.save!
  end


end
