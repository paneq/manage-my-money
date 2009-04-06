require 'test_helper'

class ValueReportTest < ActiveSupport::TestCase

  def setup
    save_jarek
  end

  test "Should create and save ValueReport" do
    r = ValueReport.new
    add_category_options @jarek, r
    r.report_view_type = :bar
    r.set_period(["10.01.2009".to_date, "17.01.2009".to_date, :LAST_WEEK])
    r.name = "Testowy raport"
    assert r.save!
  end

  test "Should validate report_view_type" do
    r = ValueReport.new
    add_category_options @jarek, r
    r.report_view_type = :pie
    r.set_period(["10.01.2009".to_date, "17.01.2009".to_date, :LAST_WEEK])
    r.name = "Testowy raport"
    assert !r.save
    assert r.errors.on(:report_view_type)
    assert_equal 1, r.errors.count
  end

  test "Should have many category options" do
    r = ValueReport.new
    add_category_options @jarek, r
    r.report_view_type = :bar
    r.set_period(["10.01.2009".to_date, "17.01.2009".to_date, :LAST_WEEK])
    r.name = "Testowy raport"
    r.category_report_options.each do |option|
      option.inclusion_type = :both
    end
    assert r.save
    assert_equal @jarek.categories.size, r.category_report_options.size
  end

end
