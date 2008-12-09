require 'test_helper'

class ReportTest < ActiveSupport::TestCase
  test "Should create and save Report" do
    r = nil
    r = Report.new
    r.period_type = :week
    r.name = "Testowy raport"
    r.report_view_type = :pie
    assert r.save
  end

  test "Should create and save Report with period" do
    r = Report.new
    r.period_type = :week
    r.report_view_type = :pie
    r.name = "Testowy raport"
    assert r.save
  end

  test "Should create and save Report with custom period" do
    r = Report.new
    r.period_type = :custom
    r.period_start = 1.day.ago
    r.period_end = 1.day.from_now
    r.name = "Testowy raport"
    r.report_view_type = :pie
    assert r.save
  end

  test "Should validate custom period and name" do
    r = Report.new
    r.period_type = :custom
    r.period_start = nil
    r.period_end = nil
    assert !r.save
    assert r.errors.on(:period_start)
    assert r.errors.on(:period_end)
    assert r.errors.on(:name)
    assert_equal 3, r.errors.count
  end

end
