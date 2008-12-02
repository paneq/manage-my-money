require 'test_helper'

class UserLoggingTest < ActionController::IntegrationTest
  #fixtures :all

  def setup
    @rupert = User.new()
    @rupert.active = true
    @rupert.email = 'email@example.com'
    @rupert.login = 'rupert'
    @rupert.password = @rupert.login
    @rupert.password_confirmation = @rupert.login
    @rupert.save!
    @rupert.activate!
  end


  test "Użytkownik może się zalogować" do
    assert_not_nil(@rupert)

    get '/'
    follow_redirect!()

    assert_response :success
    assert_template 'sessions/new'

    post session_path, { :login => @rupert.login, :password => @rupert.login }
    #follow_redirect!()
    
    #assert_equal "Witamy w serwisie.", flash[:notice]
    assert_response :success
    assert_template "categories/index"
    assert_equal @rupert.id, session['user_id']
  end
  
end
