require File.dirname(__FILE__) + '/../test_helper'
require 'exchanges_controller'

# Re-raise errors caught by the controller.
class ExchangesController; def rescue_action(e) raise e end; end

class ExchangesControllerTest < Test::Unit::TestCase

  def setup
    @controller = ExchangesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    save_currencies
    save_rupert
    log_rupert
    @chf = Currency.new(:user => @rupert, :all => 'CHF')
    @chf.save!
    @currencies << @chf
  end

  # Index all pairs of possible currencies exchanges
  def test_index
    get :index
    assert_response :success
    assert_template 'index'

    assert_select 'div#currencies-pairs-list' do
      assert_select 'li', :count => 6 # 3 + 2 + 1 possible exchanges between currencies
      @currencies.each do |currency|
        assert_select 'li', :text => Regexp.new(currency.long_symbol), :count => 3 # each currency can be exchanged to 3 other currencies
      end
    end
  end

  
  #  def test_list
  #    get :list
  #
  #    assert_response :success
  #    assert_template 'list'
  #
  #    assert_not_nil assigns(:exchanges)
  #  end
  #
  #  def test_show
  #    get :show, :id => @first_id
  #
  #    assert_response :success
  #    assert_template 'show'
  #
  #    assert_not_nil assigns(:exchange)
  #    assert assigns(:exchange).valid?
  #  end
  #
  #  def test_new
  #    get :new
  #
  #    assert_response :success
  #    assert_template 'new'
  #
  #    assert_not_nil assigns(:exchange)
  #  end
  #
  #  def test_create
  #    num_exchanges = Exchange.count
  #
  #    post :create, :exchange => {}
  #
  #    assert_response :redirect
  #    assert_redirected_to :action => 'list'
  #
  #    assert_equal num_exchanges + 1, Exchange.count
  #  end
  #
  #  def test_edit
  #    get :edit, :id => @first_id
  #
  #    assert_response :success
  #    assert_template 'edit'
  #
  #    assert_not_nil assigns(:exchange)
  #    assert assigns(:exchange).valid?
  #  end
  #
  #  def test_update
  #    post :update, :id => @first_id
  #    assert_response :redirect
  #    assert_redirected_to :action => 'show', :id => @first_id
  #  end
  #
  #  def test_destroy
  #    assert_nothing_raised {
  #      Exchange.find(@first_id)
  #    }
  #
  #    post :destroy, :id => @first_id
  #    assert_response :redirect
  #    assert_redirected_to :action => 'list'
  #
  #    assert_raise(ActiveRecord::RecordNotFound) {
  #      Exchange.find(@first_id)
  #    }
  #  end
end
