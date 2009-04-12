require 'test_helper'

# Re-raise errors caught by the controller.
class ExchangesController; def rescue_action(e) raise e end; end

class ExchangesControllerTest < ActionController::TestCase

  def setup
    prepare_currencies
    save_rupert
    save_jarek
    log_rupert
    @chf = Currency.create!(:user => @rupert, :all => 'CHF')
    @bad = Currency.create!(:user => @jarek, :all => 'BAD')
    @currencies << @chf
  end

  # Index all pairs of possible currencies exchanges
  def test_index
    get :index
    assert_response :success
    assert_template 'index'

    assert_not_nil assigns(:pairs)

    assert_select 'div#currencies-pairs-list' do
      #security: valid count checks also that other user currencies are not included
      assert_select 'li', :count => 6 # 3 + 2 + 1 possible exchanges between currencies
      @currencies.each do |currency|
        assert_select 'li', :text => Regexp.new(currency.long_symbol), :count => 3 # each currency can be exchanged to 3 other currencies
      end
      #security:
      assert_select 'li', :text => Regexp.new(@bad.long_symbol), :count => 0
    end
  end

  
  def test_list_listing
    30.times do |nr|
      Exchange.new(
        :user => @rupert,
        :left_currency => @zloty,
        :right_currency => @chf,
        :left_to_right => 0.25,
        :right_to_left => 4,
        :day => nr.days.ago.to_date).save!
    end

    get :list, :left_currency => @chf.id.to_s, :right_currency => @zloty.id.to_s
  
    assert_response :success
    assert_template 'list'

    [:currencies, :exchanges, :c1, :c2].each {|sym| assert_not_nil assigns(sym)}
    assert_select 'table#exchanges-list' do
      assert_select 'tr', :count => 20 + 1
      assert_select 'tr', :text => Regexp.new(Date.today.to_s)
      assert_select 'tr', :text => Regexp.new(19.days.ago.to_date.to_s)
    end

    assert_select 'div.pagination' do
      assert_select '[class~=prev_page]', :text => 'Późniejsze'
      assert_select '[class~=next_page]', :text => 'Wcześniejsze'
    end
  end


  def test_list_page
    30.times do |nr|
      Exchange.new(
        :user => @rupert,
        :left_currency => @zloty,
        :right_currency => @chf,
        :left_to_right => 0.25,
        :right_to_left => 4,
        :day => nr.days.ago.to_date).save!
    end

    get :list,
      :left_currency => @chf.id.to_s,
      :right_currency => @zloty.id.to_s,
      :page => 2

    assert_response :success
    assert_template 'list'

    [:currencies, :exchanges, :c1, :c2].each {|sym| assert_not_nil assigns(sym)}
    assert_select 'table#exchanges-list' do
      assert_select 'tr', :count => 10 + 1
      assert_select 'tr', :text => Regexp.new(20.days.ago.to_date.to_s)
      assert_select 'tr', :text => Regexp.new(29.days.ago.to_date.to_s)
    end

    assert_select 'div.pagination'
  end


  def test_list_new_exchange
    get :list,
      :left_currency => @chf.id.to_s,
      :right_currency => @zloty.id.to_s,
      :page => 2

    assert_not_nil assigns(:exchange)

    assert_select 'div#show-exchange' do
      assert_exchange_form(@zloty, @chf)
    end
  end


  def test_create
    num_exchanges = Exchange.count

    @request.env["HTTP_REFERER"] = "exchanges/#{@euro.id}/#{@zloty.id}?page=1"

    post :create, :exchange => {
      :left_currency => @zloty.id.to_s,
      :right_currency => @euro.id.to_s,
      :left_to_right => 0.25.to_s,
      :right_to_left => 4.to_s,
      :day => Date.today
    }

    assert_response :redirect
    assert_redirected_to :action => 'list',
      :left_currency => @euro.id.to_s,
      :right_currency => @zloty.id.to_s,
      :page => 1

    assert_match(/Utworzono/, flash[:notice])

    assert_equal num_exchanges + 1, Exchange.count
  end


  def test_list_error_after_create
    back = @request.env["HTTP_REFERER"] = "exchanges/#{@euro.id}/#{@zloty.id}?page=1"
    post :create, :exchange => {
      :left_currency => @euro.id.to_s, #same currencies -> error
      :right_currency => @euro.id.to_s,
      :left_to_right => 0.25.to_s,
      :right_to_left => 4.to_s,
      :day => Date.today
    }

    assert_response :redirect
    assert_match(/niepomyślnie/, flash[:notice])
    assert_redirected_to back

    back = @request.env["HTTP_REFERER"] = "exchanges/#{@euro.id}/#{@zloty.id}?page=1"
    post :create, :exchange => {
      :left_currency => @euro.id.to_s,
      :right_currency => @zloty.id.to_s,
      :left_to_right => 0.25.to_s,
      :right_to_left => 4.to_s,
      #no day set -> required in exchanges controller -> should cause error
    }

    assert_response :redirect
    assert_match(/niepomyślnie/, flash[:notice])
    assert_redirected_to back
  end


  def test_list_error_after_redirected
    e = Exchange.new(
      :left_currency => @euro, #same currencies -> error
      :right_currency => @euro,
      :left_to_right => 0.25,
      :right_to_left => 4,
      :day => Date.today,
      :user => @rupert
    )
    assert !e.valid?

    get :list,{
      :left_currency => @euro.id.to_s,
      :right_currency => @zloty.id.to_s,
      :page => 2}, {:user_id => @rupert.id}, {:exchange => e}

    assert_response :success
    assert_template 'list'

    assert_select 'table#exchanges-list'
    assert_select 'div#errorExplanation'

    assert_exchange_form(@euro, @euro, '0.25', '4')
  end


  def test_show_and_edit
    e = save_exchange()
    [:show, :edit].each do |action|
      get action, :id => e.id

      assert_response :success
      assert_template 'edit'

      assert_not_nil assigns(:exchange)
      assert assigns(:exchange).valid?
      assert_exchange_form(e.left_currency, e.right_currency, "%.4f" % e.left_to_right, "%.4f" % e.right_to_left) #showing 4 digits after comma/dot with Kernel.sprintf
    end
  end


  def test_new
    get :new

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:exchange)

    default = @rupert.default_currency
    rest = Currency.for_user(@rupert) - [default]
    assert_exchange_form(@rupert.default_currency, rest.first)
  end
  

  def test_update
    e = save_exchange()
    put :update, :id => e.id,
      :exchange => {
      :left_to_right => 8.to_s,
      :right_to_left => 0.125.to_s,
      :left_currency => e.left_currency.id,
      :right_currency => e.right_currency.id
    }
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => e.id

    e = Exchange.find(e.id)
    assert_equal 8, e.left_to_right
    assert_equal 0.125, e.right_to_left
  end


  def test_destroy
    e = save_exchange()
  
    post :destroy, :id => e.id
    assert_response :redirect
    assert_redirected_to :action => 'list', :left_currency =>  e.left_currency.id, :right_currency => e.right_currency.id
  
    assert_nil Exchange.find_by_id(e.id)
  end

  def test_destroy_when_used_in_transaction
    @request.env["HTTP_REFERER"] = "/exchanges"
    t = make_simple_transfer
    t.conversions.build(:exchange => make_exchange())
    t.save!
    
    id = t.exchanges.first.id
    post :destroy, :id => id
    assert_response :redirect
    assert_match(/Nie można/, flash[:notice])
    
    assert_not_nil Exchange.find_by_id(id)
  end
  
  #security

  def test_listing_someone_exchanges
    @jarek_cur = Currency.create!(:user => @jarek, :all => 'XYZ')
    [@zloty, @chf, @bad].each do |currency|
      [[@jarek_cur, currency],[currency, @jarek_cur]].each do |c1, c2|
        get :list, :left_currency => c1.id.to_s, :right_currency => c2.id.to_s
        assert_response :redirect
        assert_redirected_to :action => :index
        assert_match(/Brak uprawnień/, flash[:notice])
      end
    end
  end

  
  def test_change_someone_exchange
    cur = Currency.create!(:user => @jarek, :all => 'XYZ')
    e = save_exchange(:user => @jarek, :left_currency => cur, :right_currency => @bad)
    [[:delete, :destroy], [:put, :update], [:get, :edit], [:get, :show]].each do |method, action|
      send(method, action, :id => e.id)
      assert_response :redirect
      assert_redirected_to :action => :index
      assert_match(/Brak uprawnień/, flash[:notice])
    end
  end

  private


  def make_exchange(options = {})
    defaults = {
      :left_currency => @euro,
      :right_currency => @zloty,
      :left_to_right => 4,
      :right_to_left => 0.25,
      :day => Date.today,
      :user => @rupert
    }
    defaults.merge!(options)
    Exchange.new(defaults)
  end


  def save_exchange(options = {})
    e = make_exchange(options)
    e.save!
    e
  end


  def assert_exchange_form(left_currency, right_currency, left_input=nil, right_input=nil)
    assert_select 'form' do
      assert_select 'select#exchange_left_currency' do
        assert_select 'option[selected=selected]', left_currency.long_symbol
      end
      assert_select 'select#exchange_right_currency' do
        assert_select 'option[selected=selected]', right_currency.long_symbol
      end

      assert_select 'input#exchange_left_to_right'
      assert_select 'input#exchange_right_to_left'
      
      assert_select "input[id=exchange_left_to_right][value=#{left_input.to_s}]" unless left_input.nil?
      assert_select "input[id=exchange_right_to_left][value=#{right_input.to_s}]" unless left_input.nil?

      assert_select 'select[id^=exchange_day]', :count => 3
    end
  end

end
