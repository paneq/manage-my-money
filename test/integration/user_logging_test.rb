require 'test_helper'

class UserLoggingTest < ActionController::IntegrationTest
  #fixtures :all

  def setup
    save_rupert
  end


  test "Użytkownik może się zalogować oraz wylogować" do
    assert_not_nil(@rupert)
    
    get_via_redirect '/'
    assert_response :success
    assert_template 'sessions/new'
    
    post_via_redirect '/session', { :login => @rupert.login, :password => @rupert.login }
    assert_response :success
    assert_template "categories/index"
    assert_equal @rupert.id, session[:user_id]
    assert_equal "Witamy w serwisie.", flash[:notice]

    post_via_redirect "/logout"
    assert_response :success
    assert_template "sessions/new"
    assert_nil session[:user_id]
  end
  
end
