require 'test_helper'

class ReportTest < ActiveSupport::TestCase
  test "Should create and save Report" do
    r = nil
    r = Report.new
    r.set_period(["10.01.2009".to_date, "17.01.2009".to_date, :LAST_WEEK])
    r.name = "Testowy raport"
    r.report_view_type = :pie
    assert r.save
  end

  test "Should create and save Report with period" do
    r = Report.new
    r.set_period(["10.01.2009".to_date, "17.01.2009".to_date, :LAST_WEEK])
    r.report_view_type = :pie
    r.name = "Testowy raport"
    assert r.save
  end

  test "Should create and save Report with custom period" do
    r = Report.new
    r.period_type = :SELECTED
    r.period_start = 1.day.ago
    r.period_end = 1.day.from_now
    r.name = "Testowy raport"
    r.report_view_type = :pie
    assert r.save
  end

  test "Should validate custom period and name" do
    r = Report.new
    r.period_type = :SELECTED
    r.period_start = nil
    r.period_end = nil
    assert !r.save
    assert r.errors.on(:period_start)
    assert r.errors.on(:period_end)
    assert r.errors.on(:name)
    assert_equal 3, r.errors.count
  end

  test "Should work well with relative periods" do
    r = Report.new
    r.name = 'A'
    r.period_type = :LAST_WEEK
    r.relative_period = true
    r.report_view_type = :pie

    period = Date.calculate(:LAST_WEEK)

    assert_equal period.begin, r.period_start
    assert_equal period.end, r.period_end

    r.period_start = nil
    r.period_end = nil

    r.save!

    assert_equal period.begin, r.period_start
    assert_equal period.end, r.period_end

    r.relative_period = false
    
    r.period_start = Date.today
    r.period_end = Date.today

    r.save!

    assert_equal Date.today, r.period_start
    assert_equal Date.today, r.period_end


    #TODO find way to change Date.today value and test it!
    #    class Date
    #      def self.today
    #        '06.01.2008'.to_date
    #      end
    #    end
    #
    #    r.period_type = :THIS_MONTH
    #    r.relative_period = true
    #
    #    r.save!
    #
    #
    #    assert_equal '01.01.2008'.to_date, r.period_start
    #    assert_equal '31.01.2008'.to_date, r.period_end





    #    r.relative_period = false
    #
    #    r.period_type = :SELECTED




  end

end
