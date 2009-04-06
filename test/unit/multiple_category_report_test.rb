require 'test_helper'

class MultipleCategoryReportTest < ActiveSupport::TestCase
  
  def setup
    save_jarek
  end
  
  test "Should create and save MultipleCategoryReport" do
    r = MultipleCategoryReport.new
    add_category_options @jarek, r
    r.report_view_type = :bar
    r.set_period(["10.01.2009".to_date, "17.01.2009".to_date, :LAST_WEEK])
    r.name = "Testowy raport"
    assert r.save!
    assert_equal @jarek.categories.size, r.categories.size
    assert_equal @jarek.categories.size, r.category_report_options.size
    @jarek.categories.each do |c|
      assert_not_nil c.multiple_category_reports
      assert_equal 1, c.multiple_category_reports.size
      assert_equal r, c.multiple_category_reports.first
    end
  end

  test "Should not save MultipleCategoryReport with errors" do
    r = MultipleCategoryReport.new
    r.report_view_type = :linear
    r.name = "Testowy raport"
    add_category_options @jarek, r
    assert !r.save
    assert r.errors.on(:period_type)
    assert r.errors.on(:period_start)
    assert r.errors.on(:period_end)
    assert_equal 3, r.errors.count
  end

  test "Should not save MultipleCategoryReport without categories" do
    r = MultipleCategoryReport.new
    r.report_view_type = :linear
    r.name = "Testowy raport"
    r.set_period(["10.01.2009".to_date, "17.01.2009".to_date, :LAST_WEEK])
    assert !r.save
    assert r.errors.on(:base)
    r.category_report_options = []
    assert !r.save
    assert r.errors.on(:base)
    assert_equal 1, r.errors.count
  end

end
