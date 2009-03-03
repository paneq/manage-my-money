require File.dirname(__FILE__) + '/../test_helper'
require File.join(File.dirname(__FILE__) + "/../bdrb_test_helper")
require "goal_worker"


class GoalWorkerTest < Test::Unit::TestCase

  def setup
    @worker = GoalWorker.new
  end

  #TODO
  def test_create_goals_for_next_cycle
    assert_nothing_raised do 
      @worker.create_goals_for_next_cycle
    end
  end


  
end
