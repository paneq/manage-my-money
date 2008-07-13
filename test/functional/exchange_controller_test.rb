require File.dirname(__FILE__) + '/../test_helper'
require 'exchange_controller'

# Re-raise errors caught by the controller.
class ExchangeController; def rescue_action(e) raise e end; end

class ExchangeControllerTest < Test::Unit::TestCase
  fixtures :exchanges

  def setup
    @controller = ExchangeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = exchanges(:first).id
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

    assert_not_nil assigns(:exchanges)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:exchange)
    assert assigns(:exchange).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:exchange)
  end

  def test_create
    num_exchanges = Exchange.count

    post :create, :exchange => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_exchanges + 1, Exchange.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:exchange)
    assert assigns(:exchange).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Exchange.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Exchange.find(@first_id)
    }
  end
end
