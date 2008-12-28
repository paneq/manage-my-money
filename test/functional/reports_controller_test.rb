require 'test_helper'


class ReportsControllerTest < ActionController::TestCase

  fixtures :users

  def setup
    save_jarek
    log_user(@jarek)
  end


  test "should see new report form" do
#    login_as :quentin
    get :new
  end

  test "should see index form" do
#    login_as :quentin
    get :index
  end

end
