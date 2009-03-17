require 'test_helper'

# Re-raise errors caught by the controller.
class ExchangesController; def rescue_action(e) raise e end; end

class ExchangesControllerTest < ActionController::TestCase

  def setup
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

    assert_not_nil assigns(:pairs)

    assert_select 'div#currencies-pairs-list' do
      assert_select 'li', :count => 6 # 3 + 2 + 1 possible exchanges between currencies
      @currencies.each do |currency|
        assert_select 'li', :text => Regexp.new(currency.long_symbol), :count => 3 # each currency can be exchanged to 3 other currencies
      end
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
      assert_select 'tr', :count => 20
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
      assert_select 'tr', :count => 10
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

    assert_select 'div#form-for-exchange' do
      assert_select 'form' do
        assert_select 'select#exchange_left_currency' do
          assert_select 'option[selected=selected]', @zloty.long_symbol
        end
        assert_select 'select#exchange_right_currency' do
          assert_select 'option[selected=selected]', @chf.long_symbol
        end
        assert_select 'input#exchange_left_to_right'
        assert_select 'input#exchange_right_to_left'
        assert_select 'select[id^=exchange_day]', :count => 3
      end
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
    
    assert_select 'form' do
      assert_select 'select#exchange_left_currency' do
        assert_select 'option[selected=selected]', @euro.long_symbol
      end
      assert_select 'select#exchange_right_currency' do
        assert_select 'option[selected=selected]', @euro.long_symbol
      end
      assert_select 'input[id=exchange_left_to_right][value=0.25]'
      assert_select 'input[id=exchange_right_to_left][value=4]'
      assert_select 'select[id^=exchange_day]', :count => 3
    end

  end

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
