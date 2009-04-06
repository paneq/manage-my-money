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


  test "should create value report" do
    assert_difference('Report.count') do
      post :create,
        :value_report => value_report_hash.merge(new_category_report_option_hash),
        :report_type => 'ValueReport',
        :report_day_ValueReport_period => :LAST_DAY,
        :commit => 'Zapisz'
    end
    assert_redirected_to reports_path
    created = Report.find_by_name 'Test report'
    assert_changed_value_report(created)
  end

  test "should not create value report with errors" do
    assert_no_difference('Report.count') do
      post :create,
        :value_report => value_report_hash.merge(:name => nil),
        :report_type => 'ValueReport',
        :report_day_ValueReport_period => :LAST_DAY,
        :commit => 'Zapisz'
    end
    assert_select "h2", /nie został zachowany/
  end

  test "should create flow report" do
    assert_difference('Report.count') do
      post :create,
        :flow_report => flow_report_hash.merge(new_category_report_option_hash),
        :report_type => 'FlowReport',
        :report_day_FlowReport_period => :LAST_DAY,
        :commit => 'Zapisz'
    end
    assert_redirected_to reports_path
    created = Report.find_by_name 'Test report'
    assert_changed_flow_report(created)
  end

  test "should not create flow report with errors" do
    assert_no_difference('Report.count') do
      post :create,
        :flow_report => flow_report_hash.merge(:name => nil),
        :report_type => 'FlowReport',
        :report_day_FlowReport_period => :LAST_DAY,
        :commit => 'Zapisz'
    end
    assert_select "h2", /nie został zachowany/
  end


  test "should update value report" do
    @report = create_value_report(@jarek)
    put :update,
      :id => @report.id,
      :value_report => value_report_hash,#TODO.merge(existing_category_report_option_hash(@report)),
    :report_day_ValueReport_period => :LAST_DAY,
      :commit => 'Zapisz'
    assert_redirected_to reports_path
    created = Report.find_by_name 'Test report'
    assert_changed_value_report(created)
  end
  

  test "should not update value report with errors" do
    @report = create_value_report(@jarek)
    put :update,
      :id => @report.id,
      :value_report => value_report_hash.merge(:name=>nil),
      :report_day_ValueReport_period => :LAST_DAY,
      :commit => 'Zapisz'
    assert_select "h2", /nie został zachowany/
  end


  test "should update flow report" do
    @report = create_flow_report(@jarek)
    put :update,
      :id => @report.id,
      :flow_report => flow_report_hash, #TODO.merge(existing_category_report_option_hash(@report)),
    :report_day_FlowReport_period => :LAST_DAY,
      :commit => 'Zapisz'
    assert_redirected_to reports_path
    created = Report.find_by_name 'Test report'
    assert_changed_flow_report(created)
  end


  test "should not update flow report with errors" do
    @report = create_flow_report(@jarek)
    put :update,
      :id => @report.id,
      :flow_report => flow_report_hash.merge(:name=>nil),
      :report_day_FlowReport_period => :LAST_DAY,
      :commit => 'Zapisz'
    assert_select "h2", /nie został zachowany/
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

  test "should see index form" do
    user_report = create_flow_report(@jarek)
    get :index
    assert_response :success
    assert_select 'table#report_index' do
      assert_select 'tr th#std_reports_header'
      (0..2).each do |num|
        assert_select "tr#standard_report_#{num}"
      end
      assert_select 'tr th#user_reports_header'
      assert_select "tr#user_report_#{user_report.id}"
    end
  end


  #TODO
  test "should see flow report" do
    get :show, :id => create_flow_report(@jarek).id
    assert_response :success
  end


  test "should see share report when no data available for report" do
    get :show, :id => create_share_report(@jarek).id
    assert_response :success
    assert_select 'h1#no_data_found'
  end

  
  test "should see share report" do
    save_simple_transfer(:user => @jarek, :income => @jarek.income, :outcome => @jarek.expense, :day => 1.day.ago, :currency => @zloty, :value => 100)
    report = create_share_report(@jarek, false)
    report.category = @jarek.income
    report.set_period([7.days.ago, Date.today, :LAST_WEEK])
    report.save!
    get :show, :id => report.id
    assert_response :success
    assert_select 'table#share_report_data' do
      assert_select 'td', @jarek.income.name
      assert_select 'td', '100.0', :count => 2
    end
  end



  test "should see value report" do
    save_simple_transfer(:user => @jarek, :income => @jarek.income, :outcome => @jarek.expense, :day => 1.day.ago, :currency => @zloty, :value => 100)
    report = create_value_report(@jarek, false, false)
    report.set_period([7.days.ago, Date.today, :LAST_WEEK])
    report.category_report_options << CategoryReportOption.new({:category => @jarek.income, :inclusion_type => :category_only})
    report.save!
    get :show, :id => report.id
    assert_response :success
    assert_select 'table#value_report_data' do
      assert_select 'td', @jarek.income.name
      assert_select 'td', '100.0', :count => 2
    end


  end

  test "should see value report when no data available for report" do
    get :show, :id => create_value_report(@jarek).id
    assert_response :success
    assert_select 'h1#no_data_found'
  end


  test "Should send warning when viewing report with no categories" do
    prepare_sample_catagory_tree_for_jarek
    test_category = @jarek.categories.find_by_name 'child2'

    report1 = create_share_report(@jarek, false)
    report1.category = test_category


    report2 = create_value_report(@jarek, false, false)
    report2.category_report_options << CategoryReportOption.new({:category => test_category, :inclusion_type => :both})


    test_category.save!
    report1.save!
    report2.save!

    test_category.destroy

    assert_nil Category.find_by_id test_category.id

    [report1, report2].each do |report|
      get :show, :id => report.id
      assert_template :edit
      assert_match(/musisz wybrać kategorię.*/, flash[:notice])
    end
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
      assert_select 'tr#category-option', :count => @jarek.categories.size
      @jarek.categories.each do |cat|
        assert_select "tr#category-option", :text => /#{cat.name}.*/ do
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

  def value_report_hash
    {
      :name => 'Test report',
      :report_view_type => "bar",
      :period_division =>"none",
      :relative_period => "0",
    }
  end

  def new_category_report_option_hash
    {:new_category_report_options => create_category_report_options(@jarek.categories, [@jarek.expense])}
  end


  def existing_category_report_option_hash(report)
    {:existing_category_report_options => create_category_report_options_for_update([@jarek.expense], report)}
  end




  def assert_changed_value_report(updated)
    assert_not_nil updated
    assert_equal ValueReport, updated.class
    assert_equal :bar, updated.report_view_type
    assert_equal :none, updated.period_division
    assert_equal false, updated.relative_period
    #TODO:
    #    assert_equal 1, updated.category_report_options.count
    #    assert_equal @jarek.expense.id, updated.category_report_options.first.category_id

  end


  def flow_report_hash
    {
      :name => 'Test report',
      :report_view_type => "text",
    }
  end

  def assert_changed_flow_report(updated)
    assert_not_nil updated
    assert_equal FlowReport, updated.class
    assert_equal :text, updated.report_view_type
    assert_equal false, updated.relative_period
    #TODO:
    #    assert_equal 1, updated.category_report_options.count
    #    assert_equal @jarek.expense.id, updated.category_report_options.first.category_id
  end


  def create_category_report_options(categories, selected_categories)
    category_report_options = []
    selected_categories.each do |cat|
      category_report_options << {:inclusion_type => "category_only", :category_id => cat.id}
    end
    (categories - selected_categories).each do |cat|
      category_report_options <<{:inclusion_type => "none", :category_id => cat.id}
    end
    category_report_options
  end


  def create_category_report_options_for_update(selected_categories, report)
    existing_category_options = {}
    selected_category_ids = selected_categories.map(&:id)
    report.category_report_options.to_a.each do |opt|
      existing_category_options[opt.id] = if selected_category_ids.include?(opt.category_id)
        {:inclusion_type => "category_only", :category_id => opt.category_id}
      else
        {:inclusion_type => "none", :category_id => opt.category_id}
      end
    end
    existing_category_options
  end

end
