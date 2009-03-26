 require 'test_helper'

class ReportGraphsTest < ActionController::IntegrationTest

  def setup
    save_rupert
    require_memcached
  end

  
  test "should get json data for value report" do
    get_via_redirect '/'
    post_via_redirect '/session', { :login => @rupert.login, :password => @rupert.login }

    report_id = create_value_report(@rupert).id
    save_simple_transfer({})
    get "/reports/#{report_id}"
    assert_response :success
    get "/reports/get_graph_data/#{report_id}.json?graph=PLN"
    assert_response :success
    assert_match(/elements/, response.body)
  end

end