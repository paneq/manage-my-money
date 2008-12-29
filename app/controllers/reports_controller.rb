class ReportsController < ApplicationController

 layout 'main'
 before_filter :login_required

 def index
   @user_reports = Report.find :all, :conditions => ["user_id = ?", self.current_user.id]
   @system_reports = prepare_system_reports
 end

 def show
   
 end

 def new
#   @report = ShareReport.new
#   @share_types = ShareReport.SHARE_TYPES.keys
 end

 def create
   @report = nil
   case params[:report_type]
   when 'ShareReport'
     params[:share_report]['category'] = Category.find params[:share_report]['category'] #TODO i dont like this code
     @report = ShareReport.new(params[:share_report])
   when 'ValueReport'
     @report = ValueReport.new(params[:value_report])
   when 'FlowReport'
     @report = FlowReport.new(params[:flow_report])
   else
     raise 'Unknown Report Class'
   end

   @report.user = @current_user
   @report.period_type = :custom #TODO
   @report.period_start, @report.period_end = get_period('report_day')

   if @report.save
     flash[:notice] = "Twoj raport zostal dodany"
     redirect_to :action => :index
   else
     flash[:error]  = "Nie udalo sie dodac raportu"
     @partial_name = get_report_partial_name @report
     render :action => 'new'
   end

 end

 def destroy
    @report = Report.find params[:id]
    @report.destroy
    flash[:notice] = 'Raport zostal pomyslnie usuniety'
    redirect_to :action => :index
 end

 def edit
    @report = Report.find params[:id]
    @partial_name = get_report_partial_name @report
 end

 def update
   @report = Report.find params[:id]
   if @report.update_attributes(params[:report])
      flash[:notice] = 'Raport zostal pomyslnie zapisany'
      redirect_to :action => :index
   else
     flash[:notice] = 'Raport nie zostal pomyslnie zapisany'
     @partial_name = get_report_partial_name @report
     render :action => 'edit'
   end
 end


 #xhr
 def report_type_choosen
   case params[:report_type]
   when 'ShareReport'
     @report = ShareReport.new()
   when 'ValueReport'
     @report = ValueReport.new()
   when 'FlowReport'
     @report = FlowReport.new()
   else
     raise 'Unknown Report Class'
   end

   partial_name = get_report_partial_name @report
   render :partial => partial_name

 end


 #private
 def prepare_system_reports
   reports = []
   r = ShareReport.new
   r.category = self.current_user.categories.top_of_type :ASSET
   r.report_view_type = :pie
   r.period_type = :week
   r.share_type = :percentage
   r.name = "Systemowy raport 1"
   r.save!
   reports << r

   r = ValueReport.new
   self.current_user.categories.top.each do |c|
     r.categories << c
   end
   r.report_view_type = :bar
   r.period_type = :week
   r.period_division = :none
   r.name = "Systemowy raport 2"
   r.save!
   reports << r


   reports
 end

 def get_report_partial_name(report)
   report.type.to_s.underscore + '_fields'
 end


end
