require 'test_helper'

class DateTest < ActiveSupport::TestCase
  def test_split_into_days
    dates = Date.split_period(:day, 5.day.ago.to_date, Date.today)
    assert_equal 6, dates.count
    assert_equal [
      [5.day.ago.to_date,5.day.ago.to_date],
      [4.day.ago.to_date,4.day.ago.to_date],
      [3.day.ago.to_date,3.day.ago.to_date],
      [2.day.ago.to_date,2.day.ago.to_date],
      [1.day.ago.to_date,1.day.ago.to_date],
      [Date.today,Date.today]
    ],
      dates

    dates = Date.split_period(:day, Date.yesterday, Date.today)
    assert_equal 2, dates.count
    assert_equal [
      [Date.yesterday,Date.yesterday],
      [Date.today,Date.today]
    ],
      dates

    dates = Date.split_period(:day, Date.today, Date.today)
    assert_equal 1, dates.count
    assert_equal [
      [Date.today,Date.today]
    ],
      dates

  end
  
  def test_split_into_weeks
    dates = Date.split_period(:week, "02.02.2009".to_date, "02.02.2009".to_date)
    assert_equal 1, dates.count
    assert_equal [["02.02.2009".to_date,"02.02.2009".to_date]],  dates


    dates = Date.split_period(:week, "02.02.2009".to_date, "27.02.2009".to_date)
    assert_equal 4, dates.count
    assert_equal [
      ["02.02.2009".to_date, "08.02.2009".to_date],
      ["09.02.2009".to_date, "15.02.2009".to_date],
      ["16.02.2009".to_date, "22.02.2009".to_date],
      ["23.02.2009".to_date, "27.02.2009".to_date]
    ],
      dates

    dates = Date.split_period(:week, "04.02.2009".to_date, "27.02.2009".to_date)
    assert_equal 4, dates.count
    assert_equal [
      ["04.02.2009".to_date, "08.02.2009".to_date],
      ["09.02.2009".to_date, "15.02.2009".to_date],
      ["16.02.2009".to_date, "22.02.2009".to_date],
      ["23.02.2009".to_date, "27.02.2009".to_date]
    ],
      dates



  end

  def test_split_into_months
    dates = Date.split_period(:month, "01.02.2009".to_date , "05.02.2009".to_date)
    assert_equal 1, dates.count
    assert_equal "01.02.2009".to_date, dates[0][0]
    assert_equal "05.02.2009".to_date, dates[0][1]

    dates = Date.split_period(:month, "01.02.2009".to_date , "01.02.2009".to_date)
    assert_equal 1, dates.count
    assert_equal "01.02.2009".to_date, dates[0][0]
    assert_equal "01.02.2009".to_date, dates[0][1]

    dates = Date.split_period(:month, "31.01.2009".to_date , "01.02.2009".to_date)
    assert_equal 2, dates.count
    assert_equal "31.01.2009".to_date, dates[0][0]
    assert_equal "31.01.2009".to_date, dates[0][1]
    assert_equal "01.02.2009".to_date, dates[1][0]
    assert_equal "01.02.2009".to_date, dates[1][1]


    dates = Date.split_period(:month, "04.02.2009".to_date , "18.02.2009".to_date)
    assert_equal 1, dates.count
    assert_equal "04.02.2009".to_date, dates[0][0]
    assert_equal "18.02.2009".to_date, dates[0][1]

    dates = Date.split_period(:month, "13.01.2009".to_date , "18.02.2009".to_date)
    assert_equal 2, dates.count
    assert_equal "13.01.2009".to_date, dates[0][0]
    assert_equal "31.01.2009".to_date, dates[0][1]
    assert_equal "01.02.2009".to_date, dates[1][0]
    assert_equal "18.02.2009".to_date, dates[1][1]

    dates = Date.split_period(:month, "01.01.2009".to_date , "28.02.2009".to_date)
    assert_equal 2, dates.count
    assert_equal "01.01.2009".to_date, dates[0][0]
    assert_equal "31.01.2009".to_date, dates[0][1]
    assert_equal "01.02.2009".to_date, dates[1][0]
    assert_equal "28.02.2009".to_date, dates[1][1]


    dates = Date.split_period(:month, "01.01.2009".to_date , "15.04.2009".to_date)
    assert_equal 4, dates.count
    assert_equal "01.01.2009".to_date, dates[0][0]
    assert_equal "31.01.2009".to_date, dates[0][1]
    assert_equal "01.02.2009".to_date, dates[1][0]
    assert_equal "28.02.2009".to_date, dates[1][1]
    assert_equal "01.03.2009".to_date, dates[2][0]
    assert_equal "31.03.2009".to_date, dates[2][1]
    assert_equal "01.04.2009".to_date, dates[3][0]
    assert_equal "15.04.2009".to_date, dates[3][1]
  end

  def test_split_into_quarters
    dates = Date.split_period(:quarter, "01.01.2009".to_date, "31.03.2009".to_date)
    assert_equal 1, dates.count
    assert_equal "01.01.2009".to_date, dates[0][0]
    assert_equal "31.03.2009".to_date, dates[0][1]

    dates = Date.split_period(:quarter, "04.01.2009".to_date, "31.03.2009".to_date)
    assert_equal 1, dates.count
    assert_equal "04.01.2009".to_date, dates[0][0]
    assert_equal "31.03.2009".to_date, dates[0][1]


    dates = Date.split_period(:quarter, "01.01.2009".to_date, "25.03.2009".to_date)
    assert_equal 1, dates.count
    assert_equal "01.01.2009".to_date, dates[0][0]
    assert_equal "25.03.2009".to_date, dates[0][1]

    dates = Date.split_period(:quarter, "05.02.2009".to_date, "25.03.2009".to_date)
    assert_equal 1, dates.count
    assert_equal "05.02.2009".to_date, dates[0][0]
    assert_equal "25.03.2009".to_date, dates[0][1]


    dates = Date.split_period(:quarter, "05.02.2009".to_date, "05.02.2009".to_date)
    assert_equal 1, dates.count
    assert_equal "05.02.2009".to_date, dates[0][0]
    assert_equal "05.02.2009".to_date, dates[0][1]

    dates = Date.split_period(:quarter, "05.02.2008".to_date, "05.02.2009".to_date)
    assert_equal 5, dates.count
    assert_equal "05.02.2008".to_date, dates[0][0]
    assert_equal "31.03.2008".to_date, dates[0][1]

    assert_equal "01.04.2008".to_date, dates[1][0]
    assert_equal "30.06.2008".to_date, dates[1][1]

    assert_equal "01.07.2008".to_date, dates[2][0]
    assert_equal "30.09.2008".to_date, dates[2][1]

    assert_equal "01.10.2008".to_date, dates[3][0]
    assert_equal "31.12.2008".to_date, dates[3][1]

    assert_equal "01.01.2009".to_date, dates[4][0]
    assert_equal "05.02.2009".to_date, dates[4][1]
  end

  def test_split_into_years
    dates = Date.split_period(:year, "05.02.2009".to_date, "05.02.2009".to_date)
    assert_equal 1, dates.count
    assert_equal "05.02.2009".to_date, dates[0][0]
    assert_equal "05.02.2009".to_date, dates[0][1]

    dates = Date.split_period(:year, "05.03.2009".to_date, "05.06.2009".to_date)
    assert_equal 1, dates.count
    assert_equal "05.03.2009".to_date, dates[0][0]
    assert_equal "05.06.2009".to_date, dates[0][1]

    dates = Date.split_period(:year, "01.01.2009".to_date, "31.12.2009".to_date)
    assert_equal 1, dates.count
    assert_equal "01.01.2009".to_date, dates[0][0]
    assert_equal "31.12.2009".to_date, dates[0][1]


    dates = Date.split_period(:year, "23.01.2009".to_date, "14.02.2010".to_date)
    assert_equal 2, dates.count
    assert_equal "23.01.2009".to_date, dates[0][0]
    assert_equal "31.12.2009".to_date, dates[0][1]

    assert_equal "01.01.2010".to_date, dates[1][0]
    assert_equal "14.02.2010".to_date, dates[1][1]

    dates = Date.split_period(:year, "23.01.2008".to_date, "14.02.2010".to_date)
    assert_equal 3, dates.count
    assert_equal "23.01.2008".to_date, dates[0][0]
    assert_equal "31.12.2008".to_date, dates[0][1]

    assert_equal "01.01.2009".to_date, dates[1][0]
    assert_equal "31.12.2009".to_date, dates[1][1]

    assert_equal "01.01.2010".to_date, dates[2][0]
    assert_equal "14.02.2010".to_date, dates[2][1]
  end


  def test_split_into_none
    dates = Date.split_period(:none, 5.day.ago.to_date, Date.today)
    assert_equal 5.day.ago.to_date, dates[0][0]
    assert_equal Date.today, dates[0][1]
  end
  

  def test_next_quarter
    assert_equal "01.04.2009".to_date, "01.01.2009".to_date.next_quarter
    assert_equal "01.04.2009".to_date, "01.02.2009".to_date.next_quarter
    assert_equal "01.04.2009".to_date, "11.02.2009".to_date.next_quarter
    assert_equal "01.04.2009".to_date, "31.03.2009".to_date.next_quarter
    assert_equal "01.07.2009".to_date, "01.04.2009".to_date.next_quarter
    assert_equal "01.07.2009".to_date, "12.05.2009".to_date.next_quarter
    assert_equal "01.10.2009".to_date, "12.07.2009".to_date.next_quarter
    assert_equal "01.01.2010".to_date, "14.10.2009".to_date.next_quarter
  end

  def test_last_quarter
    assert_equal "01.10.2008".to_date, "01.01.2009".to_date.last_quarter
    assert_equal "01.10.2008".to_date, "01.02.2009".to_date.last_quarter
    assert_equal "01.10.2008".to_date, "11.02.2009".to_date.last_quarter
    assert_equal "01.10.2008".to_date, "31.03.2009".to_date.last_quarter
    assert_equal "01.01.2009".to_date, "01.04.2009".to_date.last_quarter
    assert_equal "01.01.2009".to_date, "12.05.2009".to_date.last_quarter
    assert_equal "01.04.2009".to_date, "12.07.2009".to_date.last_quarter
    assert_equal "01.07.2009".to_date, "14.10.2009".to_date.last_quarter
  end


  #this test doesnt test model, but rather method in test helper;)
  #its really important !
  def test_forced_date_and_time
    forced_date = '03.01.2001'

    with_dates(forced_date) do
      assert_equal forced_date.to_date, Date.today
      assert_equal forced_date.to_time, Time.now
      assert_equal '02.01.2001'.to_date, Date.yesterday
      assert_equal '01.01.2001'.to_time, 2.days.ago
    end

    assert_not_equal forced_date.to_date, Date.today
    assert_not_equal forced_date.to_time, Time.now
    assert_not_equal '02.01.2001'.to_date, Date.yesterday
    assert_not_equal '01.01.2001'.to_time, 2.days.ago
  end

  def test_calculate

    forced_date = '16.07.2008' #sroda, 3 tydzień lipca, III kwartał, 29 tydzień 2008

    with_dates(forced_date) do
      assert_actual_periods
      assert_past_periods
      assert_future_periods
    end
  end

  def test_shift
    date = '16.07.2008'.to_date #sroda, 3 tydzień lipca, III kwartał, 29 tydzień 2008

    assert_equal '16.07.2008'.to_date, date.shift(:DAY)
    assert_equal '22.07.2008'.to_date, date.shift(:WEEK)
    assert_equal '15.08.2008'.to_date, date.shift(:MONTH)
    assert_equal '15.10.2008'.to_date, date.shift(:QUARTER)
    assert_equal '15.07.2009'.to_date, date.shift(:YEAR)
    assert_equal '22.07.2008'.to_date, date.shift(:A_7_DAYS)
    assert_equal '12.08.2008'.to_date, date.shift(:A_4_WEEKS)
    assert_equal '15.10.2008'.to_date, date.shift(:A_3_MONTHS)
    assert_equal '13.10.2008'.to_date, date.shift(:A_90_DAYS)
    assert_equal '15.07.2009'.to_date, date.shift(:A_12_MONTHS)

  end


  private
  def assert_actual_periods
    range = Date.calculate :THIS_DAY
    assert_equal '16.07.2008'.to_date, range.begin
    assert_equal '16.07.2008'.to_date, range.end

    range = Date.calculate :THIS_WEEK
    assert_equal '14.07.2008'.to_date, range.begin
    assert_equal '20.07.2008'.to_date, range.end

    range = Date.calculate :THIS_MONTH
    assert_equal '01.07.2008'.to_date, range.begin
    assert_equal '31.07.2008'.to_date, range.end

    range = Date.calculate :THIS_QUARTER
    assert_equal '01.07.2008'.to_date, range.begin
    assert_equal '30.09.2008'.to_date, range.end

    range = Date.calculate :THIS_YEAR
    assert_equal '01.01.2008'.to_date, range.begin
    assert_equal '31.12.2008'.to_date, range.end
  end

  def assert_past_periods

    range = Date.calculate :LAST_DAY
    assert_equal '15.07.2008'.to_date, range.begin
    assert_equal '15.07.2008'.to_date, range.end

    range = Date.calculate :LAST_WEEK
    assert_equal '07.07.2008'.to_date, range.begin
    assert_equal '13.07.2008'.to_date, range.end

    range = Date.calculate :LAST_7_DAYS
    assert_equal '10.07.2008'.to_date, range.begin
    assert_equal '16.07.2008'.to_date, range.end

    range = Date.calculate :LAST_MONTH
    assert_equal '01.06.2008'.to_date, range.begin
    assert_equal '30.06.2008'.to_date, range.end

    range = Date.calculate :LAST_4_WEEKS
    assert_equal '23.06.2008'.to_date, range.begin
    assert_equal '16.07.2008'.to_date, range.end

    range = Date.calculate :LAST_QUARTER
    assert_equal '01.04.2008'.to_date, range.begin
    assert_equal '30.06.2008'.to_date, range.end

    range = Date.calculate :LAST_3_MONTHS
    assert_equal '01.05.2008'.to_date, range.begin
    assert_equal '31.07.2008'.to_date, range.end

    range = Date.calculate :LAST_90_DAYS
    assert_equal '18.04.2008'.to_date, range.begin
    assert_equal '16.07.2008'.to_date, range.end

    range = Date.calculate :LAST_YEAR
    assert_equal '01.01.2007'.to_date, range.begin
    assert_equal '31.12.2007'.to_date, range.end

    range = Date.calculate :LAST_12_MONTHS
    assert_equal '01.08.2007'.to_date, range.begin
    assert_equal '31.07.2008'.to_date, range.end
  end

  def assert_future_periods
    range = Date.calculate :NEXT_DAY
    assert_equal '17.07.2008'.to_date, range.begin
    assert_equal '17.07.2008'.to_date, range.end

    range = Date.calculate :NEXT_WEEK
    assert_equal '21.07.2008'.to_date, range.begin
    assert_equal '27.07.2008'.to_date, range.end

    range = Date.calculate :NEXT_7_DAYS
    assert_equal '16.07.2008'.to_date, range.begin
    assert_equal '22.07.2008'.to_date, range.end

    range = Date.calculate :NEXT_MONTH
    assert_equal '01.08.2008'.to_date, range.begin
    assert_equal '31.08.2008'.to_date, range.end

    range = Date.calculate :NEXT_4_WEEKS
    assert_equal '16.07.2008'.to_date, range.begin
    assert_equal '13.08.2008'.to_date, range.end

    range = Date.calculate :NEXT_QUARTER
    assert_equal '01.10.2008'.to_date, range.begin
    assert_equal '31.12.2008'.to_date, range.end

    range = Date.calculate :NEXT_3_MONTHS
    assert_equal '16.07.2008'.to_date, range.begin
    assert_equal '31.10.2008'.to_date, range.end

    range = Date.calculate :NEXT_90_DAYS
    assert_equal '16.07.2008'.to_date, range.begin
    assert_equal '13.10.2008'.to_date, range.end

    range = Date.calculate :NEXT_YEAR
    assert_equal '01.01.2009'.to_date, range.begin
    assert_equal '31.12.2009'.to_date, range.end

    range = Date.calculate :NEXT_12_MONTHS
    assert_equal '16.07.2008'.to_date, range.begin
    assert_equal '16.07.2009'.to_date, range.end
  end



end