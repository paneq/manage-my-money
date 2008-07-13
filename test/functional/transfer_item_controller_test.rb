require File.dirname(__FILE__) + '/../test_helper'
require 'transfer_item_controller'

# Re-raise errors caught by the controller.
class TransferItemController; def rescue_action(e) raise e end; end

class TransferItemControllerTest < Test::Unit::TestCase
  fixtures :transfer_items

  def setup
    @controller = TransferItemController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = transfer_items(:first).id
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:transfer_items)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:transfer_item)
    assert assigns(:transfer_item).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:transfer_item)
  end

  def test_create
    num_transfer_items = TransferItem.count

    post :create, :transfer_item => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_transfer_items + 1, TransferItem.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:transfer_item)
    assert assigns(:transfer_item).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      TransferItem.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      TransferItem.find(@first_id)
    }
  end
end
