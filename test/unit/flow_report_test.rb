require 'test_helper'

class FlowReportTest < ActiveSupport::TestCase

 def setup
    save_jarek
 end

 test "Should create FlowReport" do
    r = FlowReport.new
    @jarek.categories.each do |c|
      r.categories << c
    end
    r.report_view_type = :text
    r.period_type = :week
    r.name = "Testowy raport"
    assert r.save!
 end

 test "Should have only text view type" do
    r = FlowReport.new
    @jarek.categories.each do |c|
      r.categories << c
    end
    r.report_view_type = :linear
    r.period_type = :week
    r.name = "Testowy raport"
    assert !r.save
    assert r.errors.on(:report_view_type)
    assert_equal 1, r.errors.count
  end
end
