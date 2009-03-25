class GraphBuilder

  def self.calculate_and_build_graphs(report)
    charts = nil
    if report.share_report?
      charts, values = self.generate_share_report(report)
    elsif report.value_report?
      charts, values = self.generate_value_report(report)
    else
      throw 'Wrong report type'
    end
    return values, charts
  end


  private
  def self.generate_value_report(report)
    charts = {}
    labels = Date.get_date_range_labels report.period_start, report.period_end, report.period_division
    chart_values = calculate_and_group_values_by_currencies(report)
    chart_values.each do |currency, categories|
      chart = OpenFlashChart::OpenFlashChart.new
      chart.bg_colour = 0xffffff
      #      title = Title.new("Raport '#{@report.name}' dla waluty #{currency.long_symbol}")
      #      chart.title = title
      min = nil
      max = nil
      categories.each do |label, values|
        graph = get_graph_object report
        max ||= values.max
        min ||= values.min
        max = values.max if max < values.max
        min = values.min if min > values.min
        graph.values = values
        graph.set_key(label,12)
        graph.set_tooltip("#key# <br> Wartość: #val##{currency.symbol} <br> #x_label# ")
        graph.colour = COLORS[rand(COLORS.size) ]
        chart << graph
      end
      chart.x_axis = get_x_axis_for_value_report(labels)
      chart.y_axis = get_y_axis_for_report(min, max)
      charts[currency.long_symbol] = chart
    end

    pure_values = {}
    chart_values.each do |currency, v|
      pure_values[currency.long_symbol] = {}
      pure_values[currency.long_symbol][:title] = "Raport '#{report.name}' dla waluty #{currency.long_symbol} w okresie #{report.period_start} do #{report.period_end}"
      pure_values[currency.long_symbol][:values] = v
      pure_values[currency.long_symbol][:date_labels] = labels
    end

    return charts, pure_values
  end

  def self.calculate_and_group_values_by_currencies(report)
    user = report.user
    chart_values = {}
    if user.multi_currency_balance_calculating_algorithm == :show_all_currencies
      currencies = Currency.for_user_period(user, report.period_start, report.period_end)
    else
      currencies = [user.default_currency]
    end
    report.category_report_options.each do |option|
      values = option.category.calculate_values(option.inclusion_type, report.period_division, report.period_start, report.period_end)
      values.each do |value| #pair [type,money]
        money = value[1]
        cat_label = option.category.name
        if value[0] == :category_and_subcategories
          cat_label += ' (+podkategorie)'
        end


        currencies.each do |cur|
          chart_values[cur] ||= {}
          chart_values[cur][cat_label] ||= []
          chart_values[cur][cat_label] << money.value(cur)
        end
      end
    end
    chart_values
  end


  def self.get_x_axis_for_value_report(labels)
    x_axis = OpenFlashChart::XAxis.new
    x_axis_labels = OpenFlashChart::XAxisLabels.new
    x_axis_labels.labels = labels

    if labels.size > 4
      x_axis_labels.rotate = 'diagonal'
    end

    if labels.size > 10
      x_axis_labels.steps = labels.size/10
    end

    x_axis.labels = x_axis_labels
    x_axis
  end


  def self.get_y_axis_for_report(min,max, right = false)

    y_axis = if right
      OpenFlashChart::YAxisRight.new
    else
      OpenFlashChart::YAxis.new
    end

    distance = (max - min).abs
    distance = 10 if distance < 10
    step = 10**( ( Math.log10( distance ) ).ceil() -1)

    steps = distance.to_f/step.to_f

    step /= case steps
    when 1...3 then 4
    when 3..6 then 2
    else 1
    end

    liczba = max.abs / step
    liczba = liczba.ceil if max >= 0
    liczba = liczba.floor if max < 0
    max_max = liczba * step
    max_max *= -1 if max < 0

    liczba = min.abs / step
    liczba = liczba.floor if min >= 0
    liczba = liczba.ceil if min < 0
    min_min = liczba * step
    min_min *= -1 if min < 0

    y_axis.set_range(min_min, max_max, step)
    y_axis
  end


  #todo - do some refactor here
  def self.generate_share_report(report)
    depth = if report.depth == -1
      :all
    else
      report.depth
    end
    values_in_currencies = report.category.calculate_max_share_values report.max_categories_values_count, depth, report.period_start, report.period_end

    get_label = lambda {|hash|
      if hash[:category].nil?
        'Pozostałe'
      else
        hash[:category].name + (hash[:without_subcategories]?' (bez podkategorii)':'')
      end
    }

    charts = {}
    pure_values = {}
    values_in_currencies.each do |cur, values|
      title = "Raport '#{report.name}' udziału podkategorii w kategorii #{report.category.name} w okresie #{report.period_start} do #{report.period_end}<br/>dla waluty #{cur.long_symbol}"
      chart = OpenFlashChart::OpenFlashChart.new
      chart.bg_colour = 0xffffff

      rejected_values = []
      unless values.all? {|val| val[:value].value(cur) >= 0 } || values.all? {|val| val[:value].value(cur) <= 0 }
        rejected_values, values  = values.partition {|val| val[:value].value(cur) < 0 }
      end

      graph = get_graph_object report

      sum = values.sum{|val| val[:value].value(cur)}

      pure_values[cur.long_symbol] = {}
      pure_values[cur.long_symbol][:values] = []
      pure_values[cur.long_symbol][:title] = title
      values.each do |category_hash|
        value = category_hash[:value].value(cur)
        pure_values[cur.long_symbol][:values] << {:label => get_label.call(category_hash), :value => value, :percent => (value/sum*100).round(2)}
      end

      rejected_values.each do |category_hash|
        value = category_hash[:value].value(cur)
        pure_values[cur.long_symbol][:values] << {:label => get_label.call(category_hash), :value => value, :percent => 0}
      end



      pure_values[cur.long_symbol][:sum] = sum


      if report.report_view_type == :pie
        graph.values = values.map do |val|
          OpenFlashChart::PieValue.new(val[:value].value(cur), get_label.call(val))
        end
        graph.tooltip = "#percent# <br> #label# <br> Wartość: #val##{cur.symbol} z #{sum}#{cur.symbol}"
        if values.count > 15
          graph.set_no_labels()
        end
        graph.colours = COLORS
      else
        graph.values = values.map do |val|
          value = val[:value].value(cur)
          bv = OpenFlashChart::BarValue.new(value)
          bv.set_tooltip("#{(value/sum*100).round(2)}% <br> #x_label# <br> Wartość: #val##{cur.symbol} z #{sum}#{cur.symbol} ")
          bv
        end

        x_axis = OpenFlashChart::XAxis.new
        x_axis_labels = OpenFlashChart::XAxisLabels.new
        x_axis_labels.labels = values.map {|val| get_label.call(val)}
        x_axis_labels.rotate = 'diagonal'
        x_axis.labels = x_axis_labels
        chart.x_axis = x_axis
        max = values.max{|val1, val2| val1[:value].value(cur) <=> val2[:value].value(cur) }[:value].value(cur)
        chart.y_axis = get_y_axis_for_report(0, max)
        #        chart.y_axis_right = get_y_axis_for_report(0, (max/sum)*100, true) //not working well yet :/

        y_legend = OpenFlashChart::YLegend.new("Saldo w #{cur.long_symbol}")
        y_legend.style = '{font-size: 22px; color: #000000;}'
        chart.y_legend = y_legend

      end
      chart << graph
      charts[cur.long_symbol] = chart
    end
    return charts, pure_values
  end

  def self.create_empty_graph
    chart = OpenFlashChart::OpenFlashChart.new
    chart.bg_colour = 0xeeeeee
    title = OpenFlashChart::Title.new("\n\n\n\n\nSzukany raport przedawnił się, \n przeładuj stronę.")
    title.style = '{font-size: 30px;}'
    chart.title = title
    chart << OpenFlashChart::Pie.new
    chart.to_s
  end


  def self.get_graph_object(report)
    case report.report_view_type
    when :bar then OpenFlashChart::Bar.new
    when :pie then OpenFlashChart::Pie.new
    when :linear then OpenFlashChart::Line.new
    end
  end

  def self.get_colors
    colours = []
    0x000000.step(0xFFF0F0, 1500) do |num|
      colours << "#%x"  % num
    end
    colours.shuffle
  end

  COLORS = get_colors


  ###########################
  # dobre kolorki do ustawienia: fdd84e, 6886b4, 72ae6e, d1695e, 8a6eaf, efaa43,
  # tlo: 4a465a

  


end
