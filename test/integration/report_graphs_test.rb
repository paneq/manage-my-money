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

  test "should get json data for share report" do
    get_via_redirect '/'
    post_via_redirect '/session', { :login => @rupert.login, :password => @rupert.login }

    report = create_share_report(@rupert)
    report.period_start = 5.month.ago
    report.period_end = Date.today.to_date
    report.save!

    save_simple_transfer({})
    get "/reports/#{report.id}"
    assert_response :success
    get "/reports/get_graph_data/#{report.id}.json?graph=PLN"
    assert_response :success
    assert_match(/elements/, response.body)
  end




end