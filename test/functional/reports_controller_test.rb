require 'test_helper'


class ReportsControllerTest < ActionController::TestCase

  fixtures :users

  def setup
    save_jarek
    log_user(@jarek)
  end


  test "should see new report form" do
    get :new
    assert_response :success
  end

  test "should see index form" do
    get :index
    assert_response :success
  end

  test "should see edit form" do
    get :edit, :id => create_share_report.id
    assert_response :success
    assert_select "div#share_report_options"

    get :edit, :id => create_flow_report.id
    assert_response :success
    assert_select "div#flow_report_options"

    get :edit, :id => create_value_report.id
    assert_response :success
    assert_select "div#value_report_options"

  end


  private
  def create_share_report
    r = ShareReport.new
    r.category = @jarek.categories.first
    r.report_view_type = :pie
    r.period_type = :week
    r.share_type = :percentage
    r.name = "Testowy raport"
    r.save!
    r
  end

  def create_flow_report
    r = FlowReport.new
    add_category_options @jarek, r
    r.report_view_type = :text
    r.period_type = :week
    r.name = "Testowy raport"
    r.save!
    r
  end

  def create_value_report
    r = ValueReport.new
    add_category_options @jarek, r
    r.report_view_type = :bar
    r.period_type = :week
    r.name = "Testowy raport"
    r.save!
    r
  end

end
