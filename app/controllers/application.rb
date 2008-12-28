# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include SslRequirement
  include AuthenticatedSystem
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  #
  protect_from_forgery unless ENV["RAILS_ENV"] =='test' # :secret => '2c6164eef68d2782b197c7a76a616283'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 

  filter_parameter_logging :password

  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_money_session_id'


  def period_changed_start
    @start_day = calculate_start_day(params['time'])
    render :layout => false, :template => 'application/period_changed_start'
  end

  def period_changed_end
    @end_day = calculate_end_day(params['time'])
    render :layout => false, :template => 'application/period_changed_end'
  end





  private
  


  def calculate_start_day(time)

    start_day = case time
      when 'THIS_DAY'       then Date.today
      when 'LAST_DAY'       then 1.day.ago.to_date
      when 'THIS_WEEK'      then (Date.today.wday() - 1).days.ago.to_date
      when 'LAST_WEEK'      then (Date.today.wday() + 6).days.ago.to_date
      when 'LAST_7_DAYS'    then 6.days.ago.to_date
      when 'THIS_MONTH'     then (Date.today.mday() -1).days.ago.to_date
      when 'LAST_MONTH'     then Date.new(Date.today.year, Date.today.month - 1, 1)
      when 'LAST_4_WEEKS'   then 4.weeks.ago.to_date
      when 'THIS_QUARTER'   then Date.new(Date.today.year, ((Date.today.month-1) / 3)*3 +1 , 1 )
      when 'LAST_QUARTER'   then
        if  ( (1..3).include? Date.today.month)
          Date.new( Date.today.year() - 1, 10, 1)
        else
          Date.new( Date.today.year, ((Date.today.month-1) / 3)*3 - 2 , 1)
        end
      when 'LAST_3_MONTHS'  then Date.new(2.months.ago.year, 2.months.ago.month, 1)
      when 'LAST_90_DAYS'   then 90.days.ago.to_date
      when 'THIS_YEAR'      then Date.new(Date.today.year, 1, 1)
      when 'LAST_YEAR'      then Date.new(Date.today.year() -1, 1, 1)
      when 'LAST_12_MONTHS' then 1.year.ago.to_date
      else                2.years.ago.to_date
    end
    return start_day
  end

  def calculate_end_day(time)
    end_day = case time
      when 'THIS_DAY'       then Date.today.to_date
      when 'LAST_DAY'       then 1.day.ago.to_date
      when 'THIS_WEEK'      then Date.today.to_date
      when 'LAST_WEEK'      then (Date.today.wday).days.ago.to_date
      when 'LAST_7_DAYS'    then Date.today.to_date
      when 'THIS_MONTH'     then Date.today.to_date
      when 'LAST_MONTH'     then Date.today.day.days.ago.to_date
      when 'THIS_QUARTER'   then Date.today.to_date
      when 'LAST_QUARTER'   then Date.new(Date.today.year, ((Date.today.month-1) / 3)*3 +1 , 1 ) - 1
      when 'LAST_4_WEEKS'   then Date.today.to_date
      when 'LAST_3_MONTHS'  then Date.today.to_date
      when 'LAST_90_DAYS'   then Date.today.to_date
      when 'THIS_YEAR'      then Date.today.to_date
      when 'LAST_YEAR'    then Date.new( Date.today.year() - 1 ,12, 31)
      when 'LAST_12_MONTHS' then Date.today.to_date
      else                2.years.from_now
    end
    return end_day
  end

  def get_period(period)
     if params[period + "_period"] == 'SELECTED'
      start_day = Date.new(params[period+'_start']['year'].to_i, params[period+'_start']['month'].to_i, params[period+'_start']['day'].to_i)
      end_day = Date.new(params[period+'_end']['year'].to_i, params[period+'_end']['month'].to_i, params[period+'_end']['day'].to_i)
    else
      start_day = calculate_start_day(params[period])
      end_day   = calculate_end_day(params[period])
    end
    return start_day, end_day, params[period]
  end
  
end
