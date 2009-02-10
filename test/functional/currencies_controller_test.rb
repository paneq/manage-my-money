require File.dirname(__FILE__) + '/../test_helper'
require 'currencies_controller'

# Re-raise errors caught by the controller.
class CurrenciesController; def rescue_action(e) raise e end; end

class CurrenciesControllerTest < Test::Unit::TestCase
  # fixtures :currencies

  CURRENCY_FIELDS = [:name, :symbol, :long_name, :long_symbol]
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
    assert_not_nil assigns(:currencies)
    
    assert_select 'div#currencies-index' do
      assert_select 'table#currencies-list' do
        assert_select 'th', 6
        assert_select 'tr[id^=currency]', @currencies.size + 1 # created for rupert
        Currency.for_user(@rupert).each do |c|
          assert_select "tr#currency-#{c.id}" do
            CURRENCY_FIELDS.each do |field|
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

  
  def test_show_currency
    get :show, :id => @zloty.id

    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:currency)

    assert_select "div#show-currency-#{@zloty.id}" do
      CURRENCY_FIELDS.each do |field|
        assert_select "p##{field}", Regexp.new(@zloty.send(field))
      end
    end

    assert_select "a#currencies-list"
    assert_select "a#edit-cur-#{@zloty.id}", 0 #Be sure there is no link to edit it
  end


  def test_show_non_system_currency
    id = save_currency(:user => @rupert).id
    get :show, :id => id

    assert_response :success
    assert_template 'show'

    assert_select "a#edit-cur-#{id}" #Be sure there is link to edit it
  end


  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:currency)

    CURRENCY_FIELDS.each do |field|
      assert_select "p##{field}" do
        assert_select "label[for=currency_#{field}]"
        assert_select "input#currency_#{field}"
      end
    end
    assert_select "a#currencies-list"
  end


  def test_create_no_errors
    num_currencies = Currency.count
    post_data = {}
    CURRENCY_FIELDS.each do |field|
      post_data[field] = 'CUR'
    end
    post :create, :currency => post_data

    assert_response :redirect
    assert_redirected_to :action => :index

    assert_equal num_currencies + 1, Currency.count
    assert_not_nil @rupert.currencies.find_by_symbol('CUR')
  end


  def test_create_with_errors
    num_currencies = Currency.count
    post_data = {}
    (CURRENCY_FIELDS - [:long_symbol]).each do |field|
      post_data[field] = 'CUR'
    end
    post_data[:long_symbol] = 'ABCD' #Wrong symbol. Must be 3 letters
    post :create, :currency => post_data

    assert_response :success
    assert_template 'new'

    assert_equal num_currencies, Currency.count

    assert_select 'div#errorExplanation'

    #check that previously inputed values was an input to correct
    CURRENCY_FIELDS.each do |field|
      assert_select "p##{field}" do
        assert_select "label[for=currency_#{field}]"
        assert_select "input[id=currency_#{field}][value=#{post_data[field]}]"
      end
    end
    assert_select "a#currencies-list"
  end


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
