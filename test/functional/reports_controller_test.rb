require 'test_helper'


class ReportsControllerTest < ActionController::TestCase


  def setup
    save_jarek
    prepare_sample_catagory_tree_for_jarek
    log_user(@jarek)
  end


  test "should see new report form" do
    get :new
    assert_response :success
    assert_select "input[type=radio]", :count => 3
    assert_select "div#share_report_options[style='display:none']" do
      assert_date_fields('ShareReport')
      assert_select "input#share_report_name"
      assert_select "select#share_report_report_view_type" do
        assert_select "option", :count => 2
        ['bar','pie'].each do |opt|
          assert_select "option[value=#{opt}]"
        end
      end
      assert_select "select#share_report_depth" do
        assert_select "option", :count => 7
        ['1','2','3','4','5','6','-1'].each do |opt|
          assert_select "option[value=#{opt}]"
        end
      end
      assert_select "input#share_report_max_categories_values_count"
      assert_select "select#share_report_category_id" do
        assert_select "option", :count => @jarek.categories.count
        @jarek.categories.each do |category|
          assert_select "option", category.name_with_indentation
        end
      end
      assert_select "input#share_report_submit[type=submit]"
    end

    assert_select "div#value_report_options[style='display:none']" do
      assert_date_fields('ValueReport')
      assert_select "input#value_report_name"
      assert_select "select#value_report_report_view_type" do
        assert_select "option", :count => 2
        ['bar','linear'].each do |opt|
          assert_select "option[value=#{opt}]"
        end
      end
      assert_select "select#value_report_period_division" do
        assert_select "option", :count => 6
        ['day', 'week', 'month', 'quarter', 'year', 'none'].each do |opt|
          assert_select "option[value=#{opt}]"
        end
      end

      
      assert_category_options 'value_report', 'new'

      assert_select "input#value_report_submit[type=submit]"
    end

    assert_select "div#flow_report_options[style='display:none']" do
      assert_date_fields('FlowReport')
      assert_select "input#flow_report_name"
      assert_category_options 'flow_report', 'new'
      assert_select "input#flow_report_submit[type=submit]"
    end
  end


  test "should create share report" do
    assert_difference('Report.count') do
      post :create,
        :share_report => share_report_hash,
        :report_type => 'ShareReport',
        :report_day_ShareReport_period => :LAST_DAY,
        :commit => 'Zapisz'
    end
    assert_redirected_to reports_path
    created = Report.find_by_name 'Test report'
    assert_changed_share_report(created)
  end


  test "should not create share report with errors" do
    assert_no_difference('Report.count') do
      post :create,
        :share_report => share_report_hash.merge(:depth=>'ERROR'),
        :report_type => 'ShareReport',
        :report_day_ShareReport_period => :LAST_DAY,
        :commit => 'Zapisz'
    end
    assert_select "h2", /nie został zachowany/
  end


  #TODO
  test "should create value report" do

  end

  #TODO
  test "should not create value report with errors" do

  end

  #TODO
  test "should create flow report" do

  end

  #TODO
  test "should not create flow report with errors" do

  end



  #TODO
  test "should update value report" do

  end
  
  #TODO
  test "should not update value report with errors" do

  end


  #TODO
  test "should update flow report" do

  end

  #TODO
  test "should not update flow report with errors" do

  end


  test "should update share report" do
    @report = create_share_report(@jarek)
    put :update,
      :id => @report.id,
      :share_report => share_report_hash,
      :report_day_ShareReport_period => :LAST_DAY,
      :commit => 'Zapisz'
    assert_redirected_to reports_path
    created = Report.find_by_name 'Test report'
    assert_changed_share_report(created)
  end


  test "should not update share report with errors" do
    @report = create_share_report(@jarek)
    put :update,
      :id => @report.id,
      :share_report => share_report_hash.merge(:depth=>'ERROR'),
      :report_day_ShareReport_period => :LAST_DAY,
      :commit => 'Zapisz'
    assert_select "h2", /nie został zachowany/
  end


  test "should see index form" do
    get :index
    assert_response :success
  end

  test "should see edit form for share report" do
    get :edit, :id => create_share_report(@jarek).id
    assert_response :success
    assert_select "div#share_report_options" do
      assert_date_fields('ShareReport')
      assert_select "input#share_report_name[value='Testowy raport']"
      assert_select "select#share_report_report_view_type" do
        assert_select "option", :count => 2
        ['bar','pie'].each do |opt|
          assert_select "option[value=#{opt}]"
        end
        assert_select "option[value=pie][selected=selected]"
      end
      assert_select "select#share_report_depth" do
        assert_select "option", :count => 7
        ['1','2','3','4','5','6','-1'].each do |opt|
          assert_select "option[value=#{opt}]"
        end
        assert_select "option[value=5][selected=selected]"
      end
      assert_select "input#share_report_max_categories_values_count[value=6]"
      assert_select "select#share_report_category_id" do
        assert_select "option", :count => @jarek.categories.count
        @jarek.categories.each do |category|
          assert_select "option", category.name_with_indentation
        end
        assert_select "option[selected=selected]", @jarek.categories.first.name
      end
      assert_select "input#share_report_submit[type=submit]"
    end
  end

  test "should see edit form for value report" do
    get :edit, :id => create_value_report(@jarek).id
    assert_response :success
    assert_select "div#value_report_options" do
      assert_date_fields('ValueReport')
      assert_select "input#value_report_name"
      assert_select "select#value_report_report_view_type" do
        assert_select "option", :count => 2
        ['bar','linear'].each do |opt|
          assert_select "option[value=#{opt}]"
        end
        assert_select "option[value=bar][selected=selected]"
      end
      assert_select "select#value_report_period_division" do
        assert_select "option", :count => 6
        ['day', 'week', 'month', 'quarter', 'year', 'none'].each do |opt|
          assert_select "option[value=#{opt}]"
        end
        assert_select "option[value=week][selected=selected]"
      end


      assert_category_options 'value_report', 'existing'

      assert_select "input#value_report_submit[type=submit]"
    end
  end
  
  test "should see edit form for flow report" do
    get :edit, :id => create_flow_report(@jarek).id
    assert_response :success
    assert_select "div#flow_report_options" do
      assert_date_fields('FlowReport')
      assert_select "input#flow_report_name"
      assert_category_options 'flow_report', 'existing'
      assert_select "input#flow_report_submit[type=submit]"
    end
  end

  
  #TODO
  test "should see flow report" do
    get :show, :id => create_flow_report(@jarek).id
    assert_response :success
  end


  private

  def assert_date_fields(type)
    assert_select "select#report_day_#{type}_period" do
      assert_select "option", :count => 16
    end
    assert_select "select#report_day_#{type}_start_year"
    assert_select "select#report_day_#{type}_start_month"
    assert_select "select#report_day_#{type}_start_day"
    assert_select "select#report_day_#{type}_end_year"
    assert_select "select#report_day_#{type}_end_month"
    assert_select "select#report_day_#{type}_end_day"
  end


  def assert_category_options(report_type, new_or_existing)
    assert_select 'div#categories-options' do
      assert_select 'div#category-option', :count => @jarek.categories.size
      @jarek.categories.each do |cat|
        assert_select "div#category-option", :text => /#{cat.name}.*/ do
          assert_select "select[id^=#{report_type}_#{new_or_existing}_category_report_options_]" do
            case report_type
            when 'flow_report'
              assert_select "option", :count => 2
              ['category_only','none'].each do |opt|
                assert_select "option[value=#{opt}]"
              end
            when 'value_report'
              if cat.name != 'Zasoby' && cat.name != 'test'
                assert_select "option", :count => 2
                ['category_only','none'].each do |opt|
                  assert_select "option[value=#{opt}]"
                end
              else
                assert_select "option", :count => 4
                ['category_only','none', 'both', 'category_and_subcategories'].each do |opt|
                  assert_select "option[value=#{opt}]"
                end
              end
            end
              
            #              assert_select "option[value=both][selected=selected]"
          end
        end
      end
    end
  end

  def share_report_hash
    {
      :name => 'Test report',
      :report_view_type => :pie,
      :depth => 1,
      :max_categories_values_count => 3,
      :category_id => @jarek.expense.id,
    }
  end

  def assert_changed_share_report(updated)
    assert_not_nil updated
    assert_equal ShareReport, updated.class
    assert_equal :pie, updated.report_view_type
    assert_equal 1, updated.depth
    assert_equal 3, updated.max_categories_values_count
    assert_equal @jarek.expense.id, updated.category.id
  end

end
