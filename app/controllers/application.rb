# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include SslRequirement
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_money_session_id'
  
  private
  
  ###########################
  # @author: Robert Pankowecki
  # @author: Jaroslaw Plebanski
  # @description: puts user object in @user according to user id found in session 
  #               or redirect to login action
  def find_user
    if session[:user_id].nil?
	   @user = nil
	   redirect_to :action => :login, :controller => :users
	   flash[:notice] = 'You must be logged in to do that!'
	   return nil
    else
      @user = User.find(session[:user_id])
    end
  end


  ##########################
  # @author: Robert Pankowecki
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
  
end
