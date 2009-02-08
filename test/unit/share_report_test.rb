require 'test_helper'

class ShareReportTest < ActiveSupport::TestCase
  
  def setup
    save_jarek
  end

  test "Should create and save ShareReport" do
    r = ShareReport.new
    r.category = @jarek.categories.first
    r.report_view_type = :pie
    r.period_type = :week
    r.max_categories_values_count = 1
    r.name = "Testowy raport"
    assert r.save!
  end

  test "Should not save ShareReport with errors" do
    r = ShareReport.new
    r.report_view_type = :linear
    r.name = "Testowy raport"
    r.max_categories_values_count = -10
    r.category = nil
    assert !r.save
    assert r.errors.on(:category)
    assert r.errors.on(:report_view_type)
    assert r.errors.on(:period_type)
    assert r.errors.on(:max_categories_values_count)
    assert_equal 4, r.errors.count
  end

end 
