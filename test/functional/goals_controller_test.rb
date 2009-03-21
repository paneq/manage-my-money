require 'test_helper'

class GoalsControllerTest < ActionController::TestCase

  def setup
    save_jarek
    prepare_sample_catagory_tree_for_jarek
    log_user(@jarek)
  end


  test "should get empty index" do
    get :index
    assert_response :success
    assert_select("h1", /Twoje plany/)
  end


  test "should get index" do
    create_goals
    get :index
    assert_response :success
    assert_select("h1", /Twoje plany/)
  end


  test "should get new" do
    get :new
    assert_response :success
  end


  test "should create goal" do
    assert_difference('Goal.count') do
      post :create, 
        :goal =>goal_hash,
        :goal_day_period => :NEXT_DAY
    end
    assert_redirected_to goals_path
    created = Goal.find_by_description 'Description'
    assert_changed_goal(created)

  end


  test "should not create goal with errors" do
    assert_no_difference('Goal.count') do
      post :create,
        :goal =>goal_with_errors,
        :goal_day_period => :NEXT_DAY
    end
    assert_select "h2", /nie został zachowany/
  end


  test "should get edit" do
    create_goals
    get :edit, :id => @g1.id
    assert_response :success
  end


  test "should update goal" do
    create_goals
    params = {
      :id => @g1.id,
      :goal => goal_hash,
      :goal_day_period => :NEXT_DAY
    }
    put :update, params
    assert_redirected_to goals_path
    updated = Goal.find @g1.id
    assert_changed_goal(updated)
  end


  test "should not update goal with errors" do
    create_goals
    params = {
      :id => @g1.id,
      :goal => goal_with_errors,
      :goal_day_period => :NEXT_DAY
    }
    put :update, params
    assert_select "h2", /nie został zachowany/
  end



  test "should destroy goal" do
    create_goals
    assert_difference('Goal.count', -1) do
      delete :destroy, :id => @g1.id
    end
    assert_redirected_to goals_path
  end


  private
  def create_goals
    @g1 = create_goal(true)
    @g2 = create_goal(true)
    @g3 = create_goal(false)
    @g3.finish
    @g3.save!
  end

  def assert_changed_goal(updated)
    assert_not_nil updated
    assert_equal @jarek.expense.id, updated.category.id
    assert_equal 'Description',  updated.description
    assert_equal false, updated.include_subcategories
    assert_equal :at_least, updated.goal_completion_condition
    assert_equal 5, updated.value
    assert_equal 'USD', updated.goal_type_and_currency
    assert_equal false, updated.is_cyclic
    assert_equal :NEXT_DAY, updated.period_type
    assert_equal Date.tomorrow, updated.period_start
    assert_equal Date.tomorrow, updated.period_end
  end


  def goal_hash
    {
      :category_id => @jarek.expense.id,
      :description => "Description",
      :include_subcategories => false,
      :goal_completion_condition => :at_least,
      :value => 5,
      :goal_type_and_currency => 'USD',
      :is_cyclic => false
    }
  end


  def goal_with_errors
    goal_hash.merge(:value => 'bad number')
  end



end
