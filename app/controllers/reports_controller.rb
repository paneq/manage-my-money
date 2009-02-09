class ReportsController < ApplicationController

  layout 'main'
  before_filter :login_required

  def index
    @user_reports = Report.find :all, :conditions => ["user_id = ? AND temporary = ?", self.current_user.id, false]
    @system_reports = prepare_system_reports
  end

  def show
    @report = get_report_from_params
    respond_to do |format|
      format.html do
        @virtual = params[:virtual]
        if @report.flow_report?
          @cash_flow = Category.calculate_flow_values(@report.categories, @report.period_start, @report.period_end)
          @in_sum = Report.sum_flow_values(@cash_flow[:in])
          @out_sum = Report.sum_flow_values(@cash_flow[:out])
          @delta = @in_sum - @out_sum
          render :template => 'reports/show_flow_report'
        else
          @values = calculate_and_cache_graph_data
          @graphs = {}
          @values[:values].keys.each do |currency|
            url = {:controller => 'reports', :action => 'get_graph_data', :id => @report.id, :graph => currency, :format => 'json', :virtual => params[:virtual]}
            @graphs[currency] = open_flash_chart_object(600,500, url_for(url))
          end
          render :template => 'reports/show_graph_report'
        end
      end
    end
  end


  def get_graph_data
    throw 'No report found' unless get_report_from_params
    render :text => Rails.cache.read("REPORT##{params[:id]}")[params[:graph]], :layout => false
  end




  def new
    prepare_reports
    @report = Report.new
  end

  def create
    @share_report = nil
    @value_report = nil
    @flow_report = nil
    @report = case params[:report_type]
    when 'ShareReport'
      @share_report = ShareReport.new(params[:share_report])
    when 'ValueReport'
      @value_report = ValueReport.new(params[:value_report])
    when 'FlowReport'
      @flow_report = FlowReport.new(params[:flow_report])
    else
      raise 'Unknown Report Class'
    end

    @report.user = @current_user
    @report.period_type = :custom #TODO
    @report.period_start, @report.period_end = get_period('report_day')
    if params[:commit] == 'Pokaż'
      @report.temporary = true
      @report.name = 'Tymczasowy raport' if @report.name.empty?
    end

    if @report.save
      if params[:commit] == 'Zapisz'
        flash[:notice] = "Twoj raport zostal dodany"
        redirect_to :action => :index
      else
        if params[:commit] == 'Pokaż'
          flash[:notice] = "Jesli chcesz używać tego raportu w przyszłości kliknij 'Edytuj', nadaj temu raportowi znaczącą dla Ciebie nazwę i 'Zapisz'"
        else
          flash[:notice] = "Twoj raport zostal dodany"
        end
        redirect_to :action => :show, :id => @report.id
      end
    else
      flash[:error]  = "Nie udalo sie dodac raportu"
      prepare_reports
      @partial_name = get_report_partial_name @report
      render :action => 'new'
    end

  end

  def destroy
    @report = self.current_user.reports.find params[:id]
    @report.destroy
    flash[:notice] = 'Raport zostal pomyslnie usuniety'
    redirect_to :action => :index
  end

  def edit
    @report = self.current_user.reports.find(params[:id])
    if @report.value_report? || @report.flow_report?
      @report.prepare_category_report_options @current_user.categories
    end
    @partial_name = get_report_partial_name @report
  end

  def update
    @report = self.current_user.reports.find params[:id]
    @report.period_start, @report.period_end = get_period('report_day')
    @report.temporary = false if @report.temporary && params[:commit] != 'Pokaż'
    if @report.update_attributes(params[@report.type_str.underscore.intern])
      if params[:commit] == 'Zapisz'
        flash[:notice] = 'Raport zostal pomyslnie zapisany'
        redirect_to :action => :index
      else
        if params[:commit] == 'Pokaż' && @report.temporary
          flash[:notice] = "Jesli chcesz używać tego raportu w przyszłości kliknij 'Edytuj', nadaj temu raportowi znaczącą dla Ciebie nazwę i 'Zapisz'"
        else
          flash[:notice] = "Twoj raport zostal dodany"
        end
        redirect_to :action => :show, :id => @report.id
      end
    else
      flash[:notice] = 'Raport nie zostal pomyslnie zapisany'
      if @report.value_report? || @report.flow_report?
        @report.prepare_category_report_options @current_user.categories
      end
      @partial_name = get_report_partial_name @report
      render :action => :edit
    end
  end


  def copy_report
    report = prepare_system_reports[params[:id].to_i]
    report.id = nil
    if report.save!
      flash[:notice] = 'Raport zostal pomyslnie skopiowany'
    else
      flash[:notice] = 'Raport nie zostal skopiowany'
    end
    redirect_to :action => :index
  end


  private
  def prepare_system_reports
    reports = []
    r = ShareReport.new
    r.user = @current_user
    r.category = self.current_user.categories.top_of_type :ASSET
    r.report_view_type = :pie
    r.period_type = :week
    r.name = "Systemowy raport 1"
    r.id = 0
    #   r.save!
    reports[r.id] = r

    #   r = ValueReport.new
    #   self.current_user.categories.top.each do |c|
    #     r.categories << c
    #   end
    #   r.report_view_type = :bar
    #   r.period_type = :week
    #   r.period_division = :none
    #   r.name = "Systemowy raport 2"
    #   r.save!
    #   reports << r


    reports
  end

  def get_report_partial_name(report)
    report.type_str.underscore + '_fields'
  end

  def prepare_reports
    @value_report = ValueReport.new if !@value_report
    @share_report = ShareReport.new if !@share_report
    @flow_report = FlowReport.new if !@flow_report
    @value_report.prepare_category_report_options @current_user.categories
    @flow_report.prepare_category_report_options @current_user.categories
    @flow_report.report_view_type = :text
  end


  ###########################
  # dobre kolorki do ustawienia: fdd84e, 6886b4, 72ae6e, d1695e, 8a6eaf, efaa43,
  # tlo: 4a465a

  def calculate_and_cache_graph_data
    charts = nil
    if @report.share_report?
      charts, values = generate_share_report
    elsif @report.value_report?
      charts, values = generate_value_report
    else
      throw 'Wrong report type'
    end
    Rails.cache.write("REPORT##{@report.id}", charts, :expires_in => 10.minutes)
    return values
  end

  def get_graph_object report
    case report.report_view_type
    when :bar then Bar.new
    when :pie then Pie.new
    when :linear then Line.new
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

  def get_report_from_params
    if params[:virtual]
      prepare_system_reports[params[:id].to_i]
    else
      self.current_user.reports.find params[:id]
    end
  end


  def generate_value_report
    charts = {}
    labels = Date.get_date_range_labels @report.period_start, @report.period_end, @report.period_division
    chart_values = calculate_and_group_values_by_currencies(@report)
    chart_values.each do |currency, categories|
      chart = OpenFlashChart.new
      chart.bg_colour = 0xffffff
      title = Title.new("Raport '#{@report.name}' dla waluty #{currency.long_symbol}")
      chart.title = title
      min = nil
      max = nil
      categories.each do |label, values|
        graph = get_graph_object @report
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
    pure_values[:values] = {}
    pure_values[:date_labels] = labels
    chart_values.each do |currency, v|
      pure_values[:values][currency.long_symbol] = v
    end

    return charts, pure_values
  end


  def calculate_and_group_values_by_currencies(report)
    chart_values = {}
    if self.current_user.multi_currency_balance_calculating_algorithm == :show_all_currencies
      currencies = Currency.for_user_period(self.current_user, report.period_start, report.period_end)
    else
      currencies = [self.current_user.default_currency]
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


  def get_x_axis_for_value_report(labels)
    x_axis = XAxis.new
    x_axis_labels = XAxisLabels.new
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


  def get_y_axis_for_report(min,max, right = false)
    
    y_axis = if right
        YAxisRight.new
      else
        YAxis.new
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
  def generate_share_report
    depth = if @report.depth == -1
      :all
    else
      @report.depth
    end
    values_in_currencies = @report.category.calculate_max_share_values @report.max_categories_values_count, depth, @report.period_start, @report.period_end

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
      title = Title.new("Raport '#{@report.name}' udziału podkategorii w kategorii #{@report.category.name} w okresie #{@report.period_start} do #{@report.period_end}")
#      title.style = 'font-size: 22px;'
      chart = OpenFlashChart.new
      chart.bg_colour = 0xffffff
      chart.title = title
      graph = get_graph_object @report

      sum = values.sum{|val| val[:value].value(cur)}

      pure_values[cur.long_symbol] = {}
      pure_values[cur.long_symbol][:values] = []
      values.each do |category_hash|
        value = category_hash[:value].value(cur)
        pure_values[cur.long_symbol][:values] << {:label => get_label.call(category_hash), :value => value, :percent => (value/sum*100).round(2)}
      end

      pure_values[cur.long_symbol][:sum] = sum


      if @report.report_view_type == :pie
        graph.values = values.map do |val|
          PieValue.new(val[:value].value(cur), get_label.call(val))
        end
        graph.tooltip = "#percent# <br> #label# <br> Wartość: #val##{cur.symbol} z #{sum}#{cur.symbol}"
        if values.count > 15
          graph.set_no_labels()
        end
        graph.colours = COLORS
      else
        graph.values = values.map do |val|
          value = val[:value].value(cur)
          bv = BarValue.new(value)
          bv.set_tooltip("#{(value/sum*100).round(2)}% <br> #x_label# <br> Wartość: #val##{cur.symbol} z #{sum}#{cur.symbol} ")
          bv
        end

        x_axis = XAxis.new
        x_axis_labels = XAxisLabels.new
        x_axis_labels.labels = values.map {|val| get_label.call(val)}
        x_axis_labels.rotate = 'diagonal'
        x_axis.labels = x_axis_labels
        chart.x_axis = x_axis
        max = values.max{|val1, val2| val1[:value].value(cur) <=> val2[:value].value(cur) }[:value].value(cur)
        chart.y_axis = get_y_axis_for_report(0, max)
#        chart.y_axis_right = get_y_axis_for_report(0, (max/sum)*100, true) //not working well yet :/

        y_legend = YLegend.new("Saldo w #{cur.long_symbol}")
        y_legend.style = '{font-size: 22px; color: #000000;}'
        chart.y_legend = y_legend

      end
      chart << graph
      charts[cur.long_symbol] = chart
    end
    return charts, pure_values
  end


end
