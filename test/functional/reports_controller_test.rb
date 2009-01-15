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
    assert_select "input[type=radio]", :count => 3
    assert_select "div#share_report_options[style='display:none']" do
      assert_date_fields
      assert_select "input#share_report_name"
      assert_select "select#share_report_report_view_type" do
        assert_select "option", :count => 2
        ['bar','pie'].each do |opt|
          assert_select "option[value=#{opt}]"
        end
      end
      assert_select "select#share_report_share_type" do
        assert_select "option", :count => 2
        ['percentage','value'].each do |opt|
          assert_select "option[value=#{opt}]"
        end
      end
      assert_select "input#share_report_depth"
      assert_select "input#share_report_max_categories_count"
      assert_select "select#share_report_category_id" do
        assert_select "option", :count => @jarek.categories.count
        @jarek.categories.each do |category|
          assert_select "option", category.name
        end
      end
      assert_select "input#share_report_submit[type=submit]"
    end

    assert_select "div#value_report_options[style='display:none']" do
      assert_date_fields
      assert_select "input#value_report_name"
      assert_select "select#value_report_report_view_type" do
        assert_select "option", :count => 2
        ['bar','linear'].each do |opt|
          assert_select "option[value=#{opt}]"
        end
      end
      assert_select "select#value_report_period_division" do
        assert_select "option", :count => 3
        ['none','week', 'day'].each do |opt|
          assert_select "option[value=#{opt}]"
        end
      end

      
      assert_category_options 'value_report', 'new'

      assert_select "input#value_report_submit[type=submit]"
    end

    assert_select "div#flow_report_options[style='display:none']" do
      assert_date_fields
      assert_select "input#flow_report_name"
      assert_category_options 'flow_report', 'new'
      assert_select "input#flow_report_submit[type=submit]"
    end
  end


  test "should create" do

  end


  test "should see index form" do
    get :index
    assert_response :success
  end

  test "should see edit form for share report" do
    get :edit, :id => create_share_report.id
    assert_response :success
    assert_select "div#share_report_options" do
      assert_date_fields
      assert_select "input#share_report_name[value='Testowy raport']"
      assert_select "select#share_report_report_view_type" do
        assert_select "option", :count => 2
        ['bar','pie'].each do |opt|
          assert_select "option[value=#{opt}]"
        end
        assert_select "option[value=pie][selected=selected]"
      end
      assert_select "select#share_report_share_type" do
        assert_select "option", :count => 2
        ['percentage','value'].each do |opt|
          assert_select "option[value=#{opt}]"
        end
        assert_select "option[value=percentage][selected=selected]"
      end
      assert_select "input#share_report_depth[value=5]"
      assert_select "input#share_report_max_categories_count[value=6]"
      assert_select "select#share_report_category_id" do
        assert_select "option", :count => @jarek.categories.count
        @jarek.categories.each do |category|
          assert_select "option", category.name
        end
        assert_select "option[selected=selected]", @jarek.categories.first.name
      end
      assert_select "input#share_report_submit[type=submit]"
    end
  end

  test "should see edit form for value report" do
    get :edit, :id => create_value_report.id
    assert_response :success
    assert_select "div#value_report_options" do
      assert_date_fields
      assert_select "input#value_report_name"
      assert_select "select#value_report_report_view_type" do
        assert_select "option", :count => 2
        ['bar','linear'].each do |opt|
          assert_select "option[value=#{opt}]"
        end
        assert_select "option[value=bar][selected=selected]"
      end
      assert_select "select#value_report_period_division" do
        assert_select "option", :count => 3
        ['none','week', 'day'].each do |opt|
          assert_select "option[value=#{opt}]"
        end
        assert_select "option[value=week][selected=selected]"
      end


      assert_category_options 'value_report', 'existing'

      assert_select "input#value_report_submit[type=submit]"
    end
  end
  
  test "should see edit form for flow report" do
    get :edit, :id => create_flow_report.id
    assert_response :success
    assert_select "div#flow_report_options" do
      assert_date_fields
      assert_select "input#flow_report_name"
      assert_category_options 'flow_report', 'existing'
      assert_select "input#flow_report_submit[type=submit]"
    end
  end
  
  
  

  test "should update" do
    
  end


  test "should see flow report" do
    get :show, :id => create_flow_report.id
    assert_response :success
  end





  private

  def assert_date_fields
    assert_select "select#report_day_period" do
      assert_select "option", :count => 16
    end
    assert_select "select#report_day_start_year"
    assert_select "select#report_day_start_month"
    assert_select "select#report_day_start_day"
    assert_select "select#report_day_end_year"
    assert_select "select#report_day_end_month"
    assert_select "select#report_day_end_day"
  end


  def assert_category_options(report_type, new_or_existing)
    assert_select "div#categories-options" do
        assert_select "div.category-option", :count => @jarek.categories.count
        @jarek.categories.each do |cat|
          assert_select "div.category-option", :text => /#{cat.name}.*/ do
            assert_select "select[id^=#{report_type}_#{new_or_existing}_category_report_options_]" do
              assert_select "option", :count => 4
              ['category_only','none', 'both', 'subcategory_only'].each do |opt|
                assert_select "option[value=#{opt}]"
              end
#              assert_select "option[value=both][selected=selected]"
            end
          end
        end
      end
  end

  def create_share_report
    r = ShareReport.new
    r.category = @jarek.categories.first
    r.report_view_type = :pie
    r.period_type = :week
    r.share_type = :percentage
    r.depth = 5
    r.max_categories_count = 6
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
    r.period_division = :week
    r.name = "Testowy raport"
    r.save!
    r
  end

end
