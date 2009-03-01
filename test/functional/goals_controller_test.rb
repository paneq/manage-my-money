require 'test_helper'

class GoalsControllerTest < ActionController::TestCase

  fixtures :goals

  def setup
    save_jarek
    prepare_sample_catagory_tree_for_jarek
    log_user(@jarek)
  end


#  test "should get index" do
#    get :index
#    assert_response :success
#    assert_not_nil assigns(:goals)
#  end
#
#  test "should get new" do
#    get :new
#    assert_response :success
#  end

#  test "should create goal" do
#    assert_difference('Goal.count') do
#      post :create, :goal => { }
#    end
#
#    assert_redirected_to goal_path(assigns(:goal))
#  end

#  test "should get edit" do
#    get :edit, :id => goals(:one).id
#    assert_response :success
#  end

#  test "should update goal" do
#    put :update, :id => goals(:one).id, :goal => { }
#    assert_redirected_to goal_path(assigns(:goal))
#  end

#  test "should destroy goal" do
#    assert_difference('Goal.count', -1) do
#      delete :destroy, :id => goals(:one).id
#    end
#
#    assert_redirected_to goals_path
#  end
end
