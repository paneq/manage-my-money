class Date

  #Periods recognized by calculate
  PERIODS = [
    [:THIS_DAY, 'Dzisiaj'],
    [:LAST_DAY, 'Wczoraj'],
    [:THIS_WEEK, 'Aktualny tydzień'],
    [:LAST_WEEK, 'Poprzedni tydzień'],
    [:LAST_7_DAYS, 'Ostatnie 7 dni'],
    [:THIS_MONTH, 'Aktualny miesiąc'],
    [:LAST_MONTH, 'Poprzedni miesiąc'],
    [:LAST_4_WEEKS, 'Ostatnie 4 tygodnie'],
    [:THIS_QUARTER, 'Aktualny kwartał'],
    [:LAST_QUARTER, 'Poprzedni kwartał'],
    [:LAST_3_MONTHS, 'Ostatnie 3 miesiące'],
    [:LAST_90_DAYS, 'Ostatnie 90 dni'],
    [:THIS_YEAR, 'Aktualny rok'],
    [:LAST_YEAR, 'Poprzedni rok'],
    [:LAST_12_MONTHS, 'Ostatnie 12 miesięcy'],
  ]

  RECOGNIZED_PERIODS = PERIODS.map {|symbol, name| symbol}

  @@cache = {}
  @@today = Date.today
  
  # Returns range based on given symbol
  def self.calculate(symbol)
    raise "Unrecognized period symbol" unless RECOGNIZED_PERIODS.include?(symbol)
    unless @@today == Date.today
      @@cache = {}
      @@today = Date.today
    end
    return @@cache[symbol] ||= Range.new(Date.calculate_start(symbol), Date.calculate_end(symbol))
  end


  def self.calculate_start(symbol)
    return case symbol
    when :THIS_DAY        then Date.today
    when :LAST_DAY        then Date.yesterday
    when :THIS_WEEK       then Date.today.beginning_of_week
    when :LAST_WEEK       then Date.today.beginning_of_week.yesterday.beginning_of_week
    when :LAST_7_DAYS     then 6.days.ago.to_date
    when :THIS_MONTH      then Date.today.beginning_of_month
    when :LAST_MONTH      then Date.today.months_ago(1).beginning_of_month
    when :LAST_4_WEEKS    then 3.weeks.ago.to_date.beginning_of_week
    when :THIS_QUARTER    then Date.today.beginning_of_quarter
    when :LAST_QUARTER    then Date.today.beginning_of_quarter.yesterday.beginning_of_quarter
    when :LAST_3_MONTHS   then Date.today.months_ago(2).beginning_of_month
    when :LAST_90_DAYS    then 89.days.ago.to_date
    when :THIS_YEAR       then Date.today.beginning_of_year
    when :LAST_YEAR       then Date.today.years_ago(1).beginning_of_year
    when :LAST_12_MONTHS  then Date.today.months_ago(11).beginning_of_month
    else
      raise "Unrecognized period symbol"
    end
  end

  def self.calculate_end(symbol)
    return case symbol
    when :THIS_DAY        then Date.today
    when :LAST_DAY        then Date.yesterday
    when :THIS_WEEK       then Date.today.end_of_week
    when :LAST_WEEK       then Date.today.beginning_of_week.yesterday.end_of_week
    when :LAST_7_DAYS     then Date.today
    when :THIS_MONTH      then Date.today.end_of_month
    when :LAST_MONTH      then Date.today.months_ago(1).end_of_month
    when :THIS_QUARTER    then Date.today.end_of_quarter
    when :LAST_QUARTER    then Date.today.beginning_of_quarter.yesterday
    when :LAST_4_WEEKS    then Date.today
    when :LAST_3_MONTHS   then Date.today.end_of_month
    when :LAST_90_DAYS    then Date.today
    when :THIS_YEAR       then Date.today.end_of_year
    when :LAST_YEAR       then Date.today.years_ago(1).end_of_year
    when :LAST_12_MONTHS  then Date.today.end_of_month
    else
      raise "Unrecognized period symbol"
    end
  end

end