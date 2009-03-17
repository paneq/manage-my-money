class ReportsController < ApplicationController

  layout 'main'
  before_filter :login_required

  def index
    @user_reports = Report.find :all, :conditions => ["user_id = ? AND temporary = ?", self.current_user.id, false]
    @system_reports = Report.prepare_system_reports(self.current_user)
  end

  def show
    @report = get_report_from_params
    respond_to do |format|
      format.html do
        @virtual = params[:virtual]
        unless @report.has_a_category?
          flash[:notice] = 'Nie można pokazać raportu, musisz wybrać kategorię. (Kategoria związana z tym raportem musiała zostać usunięta)'
          redirect_to edit_report_path(@report.id)
          return
        end

        if @report.flow_report?
          @cash_flow = Category.calculate_flow_values(@report.category_report_options.map{|cro| cro.category}, @report.period_start, @report.period_end)
          @in_sum = Report.sum_flow_values(@cash_flow[:in])
          @out_sum = Report.sum_flow_values(@cash_flow[:out])
          @delta = @in_sum - @out_sum
          @currencies = (@cash_flow[:in] + @cash_flow[:out]).map {|h| h[:currency]}.uniq
          render :template => 'reports/show_flow_report'
        else
          @values, graph_data = GraphBuilder.calculate_and_build_graphs(@report)
          cache_graph_data(@report, graph_data)
          @graphs = {}
          @values.keys.each do |currency|
            url = {:controller => 'reports', :action => 'get_graph_data', :id => @report.id, :graph => currency, :format => 'json', :virtual => params[:virtual]}
            @graphs[currency] = open_flash_chart_object(600,500, url_for(url))
          end
          render :template => 'reports/show_graph_report'
        end
      end
    end
  end

  
  #action for flash_chart
  def get_graph_data
    throw 'No report found' unless get_report_from_params
    report_from_cache = Rails.cache.read(report_cache_key(params[:id]))
    unless report_from_cache.nil?
      render :text => report_from_cache[params[:graph]], :layout => false
    else
      render :text => GraphBuilder.create_empty_graph, :layout => false
    end
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
    #    @report.period_start, @report.period_end, @report.period_type = get_period("report_day_#{params[:report_type]}")
    set_period_for(@report, "report_day_#{params[:report_type]}")

    if @report.relative_period
      @report.period_start = @report.period_end = nil
    end

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

    report_param_name = @report.type_str.underscore.intern
    @report.relative_period = params[report_param_name][:relative_period]

    #    @report.period_start, @report.period_end, @report.period_type = get_period("report_day_#{@report.type_str}")
    set_period_for(@report, "report_day_#{@report.type_str}")
    if @report.relative_period
      @report.period_start = @report.period_end = nil
    end

    #    @report.period_start, @report.period_end = get_period("report_day_#{@report.type_str}")
    @report.temporary = false if @report.temporary && params[:commit] != 'Pokaż'
    if @report.update_attributes(params[report_param_name])
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
    report = Report.prepare_system_reports(self.current_user, false)[params[:id].to_i]
    if report.save!
      flash[:notice] = 'Raport zostal pomyslnie skopiowany'
    else
      flash[:notice] = 'Raport nie zostal skopiowany'
    end
    redirect_to :action => :index
  end


  private
  def cache_graph_data(report, graph_data)
    Rails.cache.write(report_cache_key(report.id), graph_data, :expires_in => 10.minutes)
  end


  def get_report_partial_name(report)
    report.type_str.underscore + '_fields'
  end

  #TODO consider dodac znacznik virtual
  def report_cache_key(id)
    "#{self.current_user.id}REPORT##{id}"
  end

  def prepare_reports
    @value_report = ValueReport.new if !@value_report
    @share_report = ShareReport.new if !@share_report
    @flow_report = FlowReport.new if !@flow_report
    @value_report.prepare_category_report_options @current_user.categories
    @flow_report.prepare_category_report_options @current_user.categories
    @flow_report.report_view_type = :text
    @flow_report.period_start = @value_report.period_start = @share_report.period_start = 1.year.ago.at_beginning_of_year.to_date
    @flow_report.period_end = @value_report.period_end = @share_report.period_end = Date.today
    @share_report.max_categories_values_count = 10
  end


  def get_report_from_params
    if params[:virtual]
      Report.prepare_system_reports(self.current_user)[params[:id].to_i]
    else
      self.current_user.reports.find params[:id]
    end
  end

end
