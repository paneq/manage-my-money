require 'test_helper'

class GoalsControllerTest < ActionController::TestCase

#  fixtures :goals

  def setup
    save_jarek
    prepare_sample_catagory_tree_for_jarek
    log_user(@jarek)
  end


  test "should get empty index" do
    get :index
    assert_response :success
  end

  test "should get index" do
    create_goals
    get :index
    assert_response :success
  end


  test "should get new" do
    get :new
    assert_response :success
  end

#  test "should create goal" do
#    assert_difference('Goal.count') do
#      post :create, :goal => { }
#    end
#
#    assert_redirected_to goal_path(assigns(:goal))
#  end

  test "should get edit" do
    create_goals
    get :edit, :id => @g1.id
    assert_response :success
  end

#  test "should update goal" do
#    put :update, :id => goals(:one).id, :goal => { }
#    assert_redirected_to goal_path(assigns(:goal))
#  end

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

end
