require File.dirname(__FILE__) + '/../test_helper'
require 'currencies_controller'

# Re-raise errors caught by the controller.
class CurrenciesController; def rescue_action(e) raise e end; end

class CurrenciesControllerTest < Test::Unit::TestCase
  # fixtures :currencies

  def setup
    @controller = CurrenciesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    save_currencies
    save_rupert
    log_rupert
  end


  def test_index
    save_jarek
    save_currency() #for rupert
    save_currency(:user => @jarek)

    get :index
    assert_response :success
    assert_template 'index'
    assert_select 'div#currencies-index' do
      assert_select 'table#currencies-list' do
        assert_select 'th', 6
        assert_select 'tr[id^=currency]', @currencies.size + 1 # created for rupert
        Currency.for_user(@rupert).each do |c|
          assert_select "tr#currency-#{c.id}" do
            [:name, :symbol, :long_name, :long_symbol].each do |field|
              assert_select "td##{field}", c.send(field)
            end
            assert_select "td#system"
            assert_select "td#options" do
              ['show', 'edit', 'del'].each do |action|
                  assert_select "a##{action}-cur-#{c.id}"
              end
            end
          end
        end
      end
      assert_select 'a#add-cur'
    end

  end

  #
  #  def test_list
  #    get :list
  #
  #    assert_response :success
  #    assert_template 'list'
  #
  #    assert_not_nil assigns(:currencies)
  #  end
  #
  #  def test_show
  #    get :show, :id => @first_id
  #
  #    assert_response :success
  #    assert_template 'show'
  #
  #    assert_not_nil assigns(:currency)
  #    assert assigns(:currency).valid?
  #  end
  #
  #  def test_new
  #    get :new
  #
  #    assert_response :success
  #    assert_template 'new'
  #
  #    assert_not_nil assigns(:currency)
  #  end
  #
  #  def test_create
  #    num_currencies = Currency.count
  #
  #    post :create, :currency => {}
  #
  #    assert_response :redirect
  #    assert_redirected_to :action => 'list'
  #
  #    assert_equal num_currencies + 1, Currency.count
  #  end
  #
  #  def test_edit
  #    get :edit, :id => @first_id
  #
  #    assert_response :success
  #    assert_template 'edit'
  #
  #    assert_not_nil assigns(:currency)
  #    assert assigns(:currency).valid?
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
  #      Currency.find(@first_id)
  #    }
  #
  #    post :destroy, :id => @first_id
  #    assert_response :redirect
  #    assert_redirected_to :action => 'list'
  #
  #    assert_raise(ActiveRecord::RecordNotFound) {
  #      Currency.find(@first_id)
  #    }
  #  end
end
