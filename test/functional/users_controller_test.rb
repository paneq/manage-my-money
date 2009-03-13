require File.dirname(__FILE__) + '/../test_helper'
require 'users_controller'

# Re-raise errors caught by the controller.
class UsersController; def rescue_action(e) raise e end; end

class UsersControllerTest < Test::Unit::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.

  fixtures :users

  def setup
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    UsersController.send(:public, :current_user=)
    save_currencies
  end


  def test_should_see_proper_menu_when_registering
    get :new
    assert_select "ul#main-sidebar" do
      assert_select "li#register", /Rejestracja/

    end
  end


  def test_should_allow_signup
    assert_difference 'User.count' do
      create_user
      assert_response :redirect
    end
  end


  def test_should_require_login_on_signup
    assert_no_difference 'User.count' do
      create_user(:login => nil)
      assert assigns(:user).errors.on(:login)
      assert_response :success
    end
  end


  def test_should_require_password_on_signup
    assert_no_difference 'User.count' do
      create_user(:password => nil)
      assert assigns(:user).errors.on(:password)
      assert_response :success
    end
  end

  def test_should_require_password_confirmation_on_signup
    assert_no_difference 'User.count' do
      create_user(:password_confirmation => nil)
      assert assigns(:user).errors.on(:password_confirmation)
      assert_response :success
    end
  end

  def test_should_require_email_on_signup
    assert_no_difference 'User.count' do
      create_user(:email => nil)
      assert assigns(:user).errors.on(:email)
      assert_response :success
    end
  end
  

  
  def test_should_sign_up_user_with_activation_code
    create_user
    assigns(:user).reload
    assert_not_nil assigns(:user).activation_code
  end


  def test_should_activate_user
    assert_nil User.authenticate('aaron', 'test')
    get :activate, :activation_code => users(:aaron).activation_code
    assert_redirected_to '/login'
    assert_not_nil flash[:notice]
    assert_equal users(:aaron), User.authenticate('aaron', 'test')
  end


  def test_should_not_activate_user_without_key
    get :activate
    assert_nil flash[:notice]
  rescue ActionController::RoutingError
    # in the event your routes deny this, we'll just bow out gracefully.
  end


  def test_should_not_activate_user_with_blank_key
    get :activate, :activation_code => ''
    assert_nil flash[:notice]
  rescue ActionController::RoutingError
    # well played, sir
  end

  def test_should_not_see_user_edit_form_without_login
    get :edit
    assert_response :redirect
  end

  def test_should_not_update_user_without_login
    put :update
    assert_response :redirect
  end

  def test_should_not_destroy_user_without_login
    delete :destroy
    assert_response :redirect
  end


  def test_should_not_edit_another_user
    login_as :quentin
    get :edit, :id => users(:aaron).id
    assert_response :redirect
  end

  def test_should_not_update_another_user
    login_as :quentin
    put :update, :id => users(:aaron).id
    assert_response :redirect
  end

  def test_should_not_destroy_another_user
    login_as :quentin
    delete :destroy, :id => users(:aaron).id
    assert_response :redirect
  end


  def test_should_see_user_edit_form
    login_as :quentin
    get :edit, :id => users(:quentin).id
    user = User.find(users(:quentin).id)
    assert_response :success
    assert_select "input#user_email"
    assert_select "input#user_password"
    assert_select "select#user_transaction_amount_limit_type" do
      assert_select "option", :count => 4
    end
    assert_select "input#user_transaction_amount_limit_value"
    assert_select "input#user_include_transactions_from_subcategories"
    assert_select "fieldset#user_multi_currency_balance_calculating_algorithms" do
      assert_select "input[type=radio]", :count => 5
    end

    user_visible_currencies = user.visible_currencies
    assert_select "select#user_default_currency_id" do
      assert_select "option", :count => user_visible_currencies.count
      user_visible_currencies.each do |cur|
        assert_select "option[value=#{cur.id}]", cur.long_symbol
      end
    end
  end

   def test_should_update_user
     login_as :quentin
     params = {
       :id => users(:quentin).id,
       :user => {
         :password => nil,
         :password_confirmation => nil,
         :include_transactions_from_subcategories => '1',
         :transaction_amount_limit_type => 'transaction_count',
         :transaction_amount_limit_value => '12',
         :email => 'a@a.pl',
         :multi_currency_balance_calculating_algorithm => 'show_all_currencies',
         :default_currency_id => Currency.find(:first, :conditions => {:long_symbol => 'USD'}).id
        }
      } 
     put :update,  params
     assert_redirected_to :action => "default", :controller => :sessions
     user = User.find(users(:quentin).id)
     assert_equal true, user.include_transactions_from_subcategories
     assert_equal 12, user.transaction_amount_limit_value
     assert_equal :show_all_currencies, user.multi_currency_balance_calculating_algorithm
     assert_equal :transaction_count, user.transaction_amount_limit_type
     assert_equal Currency.find(:first, :conditions => {:long_symbol => 'USD'}).id, user.default_currency.id
   end

   def test_should_fail_user_with_errors_on_update
     login_as :quentin
     params = {
       :id => users(:quentin).id,
       :user => {
         :password => nil,
         :password_confirmation => nil,
         :email => 'a@a.pl',
         :transaction_amount_limit_type => 'transaction_count_', #<-Error
         :transaction_amount_limit_value => '12',
         :include_transactions_from_subcategories => '1',
         :multi_currency_balance_calculating_algorithm => 'show_all_currencies'
        }
      }
      assert_raise(RuntimeError, "Unknown enum value: transaction_count_") do
        put :update,  params
      end
   end

  
  protected
  def create_user(options = {})
    post :create, :user => { :login => 'quire', :email => 'quire@example.com',
      :password => 'komandosi', :password_confirmation => 'komandosi', :transaction_amount_limit_type => :actual_month }.merge(options)
  end

  
end
