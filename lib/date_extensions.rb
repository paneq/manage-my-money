class Date

  alias old_advance advance
  #Dodaje do metody advance opcje :weeks i :quarters (dodają odpowiednio po 7 dni i 3 miesiące)
  def advance(options)
    if options[:weeks]
      options[:days] ||= 0
      options[:days] += options[:weeks]*7
      options[:weeks] = nil
    end

    if options[:quarters]
      options[:months] ||= 0
      options[:months] += options[:quarters]*3
      options[:quarters] = nil
    end
    old_advance(options)
  end

  def next_quarter
    self.at_end_of_quarter.next
  end

  def last_quarter
    self.at_beginning_of_quarter.advance(:days => -1).at_beginning_of_quarter
  end

  def next_week
    self.at_end_of_week.next
  end

  def last_week
    self.at_beginning_of_week.advance(:days => -1).at_beginning_of_week
  end



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
    raise "Unrecognized period symbol: #{symbol}" unless RECOGNIZED_PERIODS.include?(symbol)
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
      raise "Unrecognized period symbol: #{symbol}"
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
      raise "Unrecognized period symbol: #{symbol}"
    end
  end


  def self.split_period(period_division, period_start, period_end)
    case period_division
    when :day then
      split_into_days(period_start, period_end)
    when :week, :month, :quarter, :year then
      meta_split_period(period_division, period_start, period_end)
    when :none then
      [[period_start, period_end]]
    end
  end


  def self.split_into_days(period_start, period_end)
    result = []
    act_date = period_start
    next_date = nil
    while act_date <= period_end do
      next_date = act_date.advance :days => 1
      result << [act_date, next_date - 1.day]
      act_date = next_date
    end
    result
  end

  private
  def self.meta_split_period(split_unit, period_start, period_end)

    beginning_method = "at_beginning_of_#{split_unit}"
    end_method = "at_end_of_#{split_unit}"
    next_method = "next_#{split_unit}"
    last_method = "last_#{split_unit}"
    adv_symbol = split_unit.to_s.pluralize.intern

    result = []
    act_date = period_start
    next_date = nil
    if period_start.send(end_method) == period_end.send(end_method)
      result << [period_start, period_end]
    else
      #1. od daty poczatkowej do konca okresu
      result << [period_start, period_start.send(end_method)]
      #2.srodek
      if period_start.send(next_method).send(end_method) != period_end.send(end_method)
        act_date = period_start.send(next_method).send(beginning_method)
        while act_date <= period_end.send(last_method).send(end_method) do
          next_date = act_date.advance adv_symbol => 1
          result << [act_date, act_date.send(end_method)]
          act_date = next_date
        end
      end
      #3.od poczatku okresu do daty koncowej
      result << [period_end.send(beginning_method), period_end]
    end
    result
  end


end