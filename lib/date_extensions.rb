module DateExtensions

  ACTUAL_PERIODS = [
    [:THIS_DAY, 'Dzisiaj'],
    [:THIS_WEEK, 'Aktualny tydzień'],
    [:THIS_MONTH, 'Aktualny miesiąc'],
    [:THIS_QUARTER, 'Aktualny kwartał'],
    [:THIS_YEAR, 'Aktualny rok'],
  ]


  #Periods recognized by calculate
  PAST_PERIODS = [
    [:LAST_DAY, 'Wczoraj'],
    [:LAST_WEEK, 'Poprzedni tydzień'],
    [:LAST_7_DAYS, 'Ostatnie 7 dni'],
    [:LAST_MONTH, 'Poprzedni miesiąc'],
    [:LAST_4_WEEKS, 'Ostatnie 4 tygodnie'],
    [:LAST_QUARTER, 'Poprzedni kwartał'],
    [:LAST_3_MONTHS, 'Ostatnie 3 miesiące'],
    [:LAST_90_DAYS, 'Ostatnie 90 dni'],
    [:LAST_YEAR, 'Poprzedni rok'],
    [:LAST_12_MONTHS, 'Ostatnie 12 miesięcy'],
  ]


  FUTURE_PERIODS = [
    [:NEXT_DAY, 'Jutro'],
    [:NEXT_WEEK, 'Następny tydzień'],
    [:NEXT_7_DAYS, 'Następne 7 dni'],
    [:NEXT_MONTH, 'Następny miesiąc'],
    [:NEXT_4_WEEKS, 'Następne 4 tygodnie'],
    [:NEXT_QUARTER, 'Następnt kwartał'],
    [:NEXT_3_MONTHS, 'Następne 3 miesiące'],
    [:NEXT_90_DAYS, 'Następne 90 dni'],
    [:NEXT_YEAR, 'Następny rok'],
    [:NEXT_12_MONTHS, 'Następne 12 miesięcy'],
  ]


  PERIOD_CATEGORIES = [
    [:DAY, 'Dzień'],
    [:WEEK, 'Tydzień'],
    [:MONTH, 'Miesiąc'],
    [:QUARTER, 'Kwartał'],
    [:YEAR, 'Rok'],
    [:A_7_DAYS, '7 dni'],
    [:A_4_WEEKS, '4 tygodnie'],
    [:A_3_MONTHS, '3 miesiące'],
    [:A_90_DAYS, '90 dni'],
    [:A_12_MONTHS, '12 miesięcy'],
  ]


  RECOGNIZED_PERIODS = (ACTUAL_PERIODS + PAST_PERIODS + FUTURE_PERIODS).map {|symbol, name| symbol}


  def self.included(mod)
    mod.extend(ClassMethods)
    mod.send :alias_method, :original_advance, :advance
    mod.send :alias_method, :advance, :extended_advance
  end

    
  #Dodaje do metody advance opcje :weeks i :quarters (dodają odpowiednio po 7 dni i 3 miesiące)
  def extended_advance(options)
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
    original_advance(options)
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


  def shift(period_category)
    case period_category
    when :DAY then self.advance(:days => 1)
    when :WEEK then self.advance(:weeks => 1)
    when :MONTH then self.advance(:months => 1)
    when :QUARTER then self.advance(:quarters => 1)
    when :YEAR then self.advance(:years => 1)
    when :A_7_DAYS then self.advance(:days => 7)
    when :A_4_WEEKS then self.advance(:weeks => 4)
    when :A_3_MONTHS then self.advance(:months => 3)
    when :A_90_DAYS then self.advance(:days => 90)
    when :A_12_MONTHS then self.advance(:months => 12)
    else
      raise "Unrecognized period symbol: #{period_category}"
    end
    
  end

  module ClassMethods
    @@__3m_date_extensions_cache = {}
    @@__3m_date_extensions_today = Date.today

    # Returns range based on given symbol
    def calculate(symbol)
      raise "Unrecognized period symbol: #{symbol}" unless RECOGNIZED_PERIODS.include?(symbol)
      unless @@__3m_date_extensions_today == Date.today
        @@__3m_date_extensions_cache = {}
        @@__3m_date_extensions_today = Date.today
      end
      return @@__3m_date_extensions_cache[symbol] ||= Range.new(Date.calculate_start(symbol), Date.calculate_end(symbol))
    end


    def calculate_start(symbol)
      return case symbol
        #actual periods
      when :THIS_DAY        then Date.today
      when :THIS_WEEK       then Date.today.beginning_of_week
      when :THIS_MONTH      then Date.today.beginning_of_month
      when :THIS_QUARTER    then Date.today.beginning_of_quarter
      when :THIS_YEAR       then Date.today.beginning_of_year
        #past periods
      when :LAST_DAY        then Date.yesterday
      when :LAST_WEEK       then Date.today.beginning_of_week.yesterday.beginning_of_week
      when :LAST_7_DAYS     then 6.days.ago.to_date
      when :LAST_MONTH      then Date.today.months_ago(1).beginning_of_month
      when :LAST_4_WEEKS    then 3.weeks.ago.to_date.beginning_of_week
      when :LAST_QUARTER    then Date.today.beginning_of_quarter.yesterday.beginning_of_quarter
      when :LAST_3_MONTHS   then Date.today.months_ago(2).beginning_of_month
      when :LAST_90_DAYS    then 89.days.ago.to_date
      when :LAST_YEAR       then Date.today.years_ago(1).beginning_of_year
      when :LAST_12_MONTHS  then Date.today.months_ago(11).beginning_of_month
        #future periods
      when :NEXT_DAY        then Date.tomorrow
      when :NEXT_WEEK       then Date.today.end_of_week.tomorrow
      when :NEXT_7_DAYS     then Date.today
      when :NEXT_MONTH      then Date.today.end_of_month.tomorrow
      when :NEXT_4_WEEKS    then Date.today
      when :NEXT_QUARTER    then Date.today.next_quarter
      when :NEXT_3_MONTHS   then Date.today
      when :NEXT_90_DAYS    then Date.today
      when :NEXT_YEAR       then Date.today.next_year.beginning_of_year
      when :NEXT_12_MONTHS  then Date.today
      else
        raise "Unrecognized period symbol: #{symbol}"
      end
    end


    def calculate_end(symbol)
      return case symbol
        #actual periods
      when :THIS_DAY        then Date.today
      when :THIS_WEEK       then Date.today.end_of_week
      when :THIS_MONTH      then Date.today.end_of_month
      when :THIS_QUARTER    then Date.today.end_of_quarter
      when :THIS_YEAR       then Date.today.end_of_year
        #past periods
      when :LAST_DAY        then Date.yesterday
      when :LAST_WEEK       then Date.today.beginning_of_week.yesterday.end_of_week
      when :LAST_7_DAYS     then Date.today
      when :LAST_MONTH      then Date.today.months_ago(1).end_of_month
      when :LAST_QUARTER    then Date.today.beginning_of_quarter.yesterday
      when :LAST_4_WEEKS    then Date.today
      when :LAST_3_MONTHS   then Date.today.end_of_month
      when :LAST_90_DAYS    then Date.today
      when :LAST_YEAR       then Date.today.years_ago(1).end_of_year
      when :LAST_12_MONTHS  then Date.today.end_of_month

        #future periods
      when :NEXT_DAY        then Date.tomorrow
      when :NEXT_WEEK       then Date.today.advance(:weeks => 1).end_of_week
      when :NEXT_7_DAYS     then Date.today.advance(:days => 6)
      when :NEXT_MONTH      then Date.today.advance(:months => 1).end_of_month
      when :NEXT_QUARTER    then Date.today.advance(:quarters => 1).end_of_quarter
      when :NEXT_4_WEEKS    then Date.today.advance(:weeks => 4)
      when :NEXT_3_MONTHS   then Date.today.advance(:months => 3).end_of_month
      when :NEXT_90_DAYS    then Date.today.advance(:days => 89)
      when :NEXT_YEAR       then Date.today.advance(:years => 1).end_of_year
      when :NEXT_12_MONTHS  then Date.today.advance(:months => 12)
      else
        raise "Unrecognized period symbol: #{symbol}"
      end
    end

    def period_category(period)
      case period
      when :THIS_DAY, :LAST_DAY, :NEXT_DAY then :DAY
      when :THIS_WEEK, :LAST_WEEK, :NEXT_WEEK then :WEEK
      when :THIS_MONTH, :LAST_MONTH, :NEXT_MONTH then :MONTH
      when :THIS_QUARTER, :LAST_QUARTER, :NEXT_QUARTER then :QUARTER
      when :THIS_YEAR, :LAST_YEAR, :NEXT_YEAR then :YEAR
      when :LAST_7_DAYS, :NEXT_7_DAYS then :A_7_DAYS
      when :LAST_4_WEEKS, :NEXT_4_WEEKS then :A_4_WEEKS
      when:LAST_3_MONTHS, :NEXT_3_MONTHS then :A_3_MONTHS
      when :LAST_90_DAYS, :NEXT_90_DAYS then :A_90_DAYS
      when :LAST_12_MONTHS, :NEXT_12_MONTHS then :A_12_MONTHS
      else
        raise "Unrecognized period symbol: #{period}"
      end
    end


    def period_category_name(period)
      PERIOD_CATEGORIES.find{|el|  el[0] == period_category(period)}[1]
    end


    def split_period(period_division, period_start, period_end)
      case period_division
      when :day then
        split_into_days(period_start, period_end)
      when :week, :month, :quarter, :year then
        meta_split_period(period_division, period_start, period_end)
      when :none then
        [[period_start, period_end]]
      end
    end


    def split_into_days(period_start, period_end)
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


    #
    # Podaje tablice etykiet dla zakresu daty z podziałem
    #
    # Parametry:
    #  period_division podział, moze być :day, :week, :month :quarter :year :none, domyślnie :none
    #  period_start, period_end zakres
    #
    # Wyjście:
    #  tablica stringów
    #  sortowanie od etykiety opisujacej najstarsza wartosc
    def get_date_range_labels(period_start, period_end, period_division = :none)
      dates = Date.split_period(period_division, period_start, period_end)
      result = []
      case period_division
      when :day then
        dates.each do |range|
          result << "#{range[0].to_s}"
        end
      when :week then
        dates.each do |range|
          result << "#{range[0].to_s} do #{range[1].to_s}"
        end
      when :month then
        dates.each do |range|
          result << I18n.l(range[0], :format => '%Y %b ')
        end
      when :quarter then
        dates.each do |range|
          result << "#{quarter_number(range[0])} kwartał #{range[0].strftime('%Y')}"
        end
      when :year then
        dates.each do |range|
          result << range[0].strftime('%Y')
        end
      when :none then
        dates.each do |range|
          result << "#{range[0].to_s} do #{range[1].to_s}"
        end
      end
      result
    end


    private
    #numer kwartału po rzymsku
    def quarter_number(date)
      case (date.at_beginning_of_quarter.month)
      when 1 then "I"
      when 4 then "II"
      when 7 then "III"
      when 10 then "IV"
      end
    end


    def meta_split_period(split_unit, period_start, period_end)

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
end
