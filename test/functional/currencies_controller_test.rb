# SECURITY
#
# verifaction tested for:
# edit
# update
# destroy

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


  def test_edit_my_currency
    currency = save_currency
    get :edit, :id => currency.id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:currency)
    assert assigns(:currency).valid?

    CURRENCY_FIELDS.each do |field|
      assert_select "p##{field}" do
        assert_select "label[for=currency_#{field}]"
        assert_select "input[id=currency_#{field}][value=#{currency.send(field)}]"
      end
    end
    assert_select "a#currencies-list"
  end


  def test_update_my_currency
    currency = save_currency(:user => @rupert)
    old_symbol = currency.symbol
    post_data = {}
    CURRENCY_FIELDS.each { |field| post_data[field] = 'CUR' }

    put :update, :id => currency.id, :currency => post_data

    assert_response :redirect
    assert_redirected_to :action => :show, :id => currency.id

    assert_nil @rupert.currencies.find_by_symbol(old_symbol)
    assert_not_nil @rupert.currencies.find_by_symbol('CUR')
  end


  def test_update_my_currency_with_errors
    currency = save_currency(:user => @rupert)
    post_data = {}
    CURRENCY_FIELDS.each { |field| post_data[field] = 'CUR' }
    post_data[:long_symbol] = 'ABCD' #too long symbol

    put :update, :id => currency.id, :currency => post_data

    assert_response :success
    assert_template 'edit'

    assert_not_nil @rupert.currencies.find_by_symbol(currency.symbol)
    assert_nil @rupert.currencies.find_by_symbol('CUR')

    #Check if fields are set with previously send values
    CURRENCY_FIELDS.each do |field|
      assert_select "p##{field}" do
        assert_select "label[for=currency_#{field}]"
        assert_select "input[id=currency_#{field}][value=#{post_data[field]}]"
      end
    end
    assert_select "a#currencies-list"
  end


  def test_destroy
    currency = save_currency
    post :destroy, :id => currency.id
    
    assert_response :redirect
    assert_redirected_to :action => :index
    assert_nil Currency.find_by_id(currency.id)
  end


  def test_destroy_currency_with_items
    currency = save_currency
    save_simple_transfer(:currency => currency)
    post :destroy, :id => currency.id

    assert_response :redirect
    assert_redirected_to :action => :index

    assert_not_nil Currency.find_by_id(currency.id)

    assert_match(/Nie można/, flash[:notice])
  end


  # SECURITY
  def test_security_destroy_update_edit_system_or_someone_currency
    save_jarek
    currency = save_currency(:user => @jarek)
    [[:delete, :destroy], [:put, :update], [:get, :edit]].each do |method, action|
      [currency, @zloty].each do |bad_currency|
        send method, action, :id => bad_currency.id

        assert_response :redirect
        assert_redirected_to :action => :index
        assert_match(/Brak uprawnień/, flash[:notice])
      end
    end
  end

end
