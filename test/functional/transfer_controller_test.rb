require File.dirname(__FILE__) + '/../test_helper'
require 'transfer_controller'

# Re-raise errors caught by the controller.
class TransferController; def rescue_action(e) raise e end; end

class TransferControllerTest < Test::Unit::TestCase
  fixtures :transfers

  def setup
    @controller = TransferController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = transfers(:first).id
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

    assert_not_nil assigns(:transfers)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:transfer)
    assert assigns(:transfer).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:transfer)
  end

  def test_create
    num_transfers = Transfer.count

    post :create, :transfer => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_transfers + 1, Transfer.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:transfer)
    assert assigns(:transfer).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Transfer.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Transfer.find(@first_id)
    }
  end
end
