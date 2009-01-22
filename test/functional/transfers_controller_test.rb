require File.dirname(__FILE__) + '/../test_helper'
require 'transfers_controller'

# Re-raise errors caught by the controller.
class TransfersController; def rescue_action(e) raise e end; end

class TransfersControllerTest < Test::Unit::TestCase


  def setup
    @controller = TransfersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    save_currencies
    save_rupert
    log_rupert
  end

  def test_index
    get :index
    assert_response :success
    assert_select 'div#transfer-table-div'
  end

  def test_index_menu
    get :index
    menu ['full', 'search'], '/transfers/search'
  end
end