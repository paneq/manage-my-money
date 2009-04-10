require 'test_helper'

class ShareReportTest < ActiveSupport::TestCase
  
  def setup
    save_jarek
  end

  test "Should create and save ShareReport" do
    r = ShareReport.new
    r.user = @jarek
    r.category = @jarek.categories.first
    r.report_view_type = :pie
    r.set_period(["10.01.2009".to_date, "17.01.2009".to_date, :LAST_WEEK])
    r.max_categories_values_count = 1
    r.name = "Testowy raport"
    assert r.save!
  end

  test "Should not save ShareReport with errors" do
    r = ShareReport.new
    r.user = @jarek
    r.report_view_type = :linear
    r.name = "Testowy raport"
    r.max_categories_values_count = -10
    r.category = nil
    assert !r.save
    assert r.errors.on(:category)
    assert r.errors.on(:report_view_type)
    assert r.errors.on(:period_type)
    assert r.errors.on(:period_start)
    assert r.errors.on(:period_end)
    assert r.errors.on(:max_categories_values_count)
    assert_equal 6, r.errors.count
  end


  test "should validate category user" do
    save_rupert
    r = ShareReport.new
    r.user = @jarek
    r.category = @rupert.income
    r.report_view_type = :pie
    r.set_period(["10.01.2009".to_date, "17.01.2009".to_date, :LAST_WEEK])
    r.max_categories_values_count = 1
    r.name = "Testowy raport"
    assert !r.save
    assert r.errors.on(:user_id)
    assert_equal 1, r.errors.count
  end



end 
