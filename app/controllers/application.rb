# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'date'

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

  def create_empty_transfer
    @transfer = Transfer.new(:day => Date.today)
    @transfer.transfer_items.build(:transfer_item_type => :income)
    @transfer.transfer_items.build(:transfer_item_type => :outcome)
  end

  
  def set_variables_for_rendering_transfer_table
    set_current_category
    set_start_end_days
    set_transfers_and_values
  end

  
  def set_current_category
    @category ||= self.current_user.categories.find(params['current_category']) if params['current_category']
  end


  def set_start_end_days
    @start_day ||= @transfer.day.beginning_of_month if @transfer
    @end_day ||= @transfer.day.end_of_month if @transfer
    @start_day ||= @range.begin if @range
    @end_day ||= @range.end if @range
  end


  def set_transfers_and_values
    if @category
      @transfers ||= @category.transfers_with_saldo_for_period_new(@start_day.to_date , @end_day.to_date)
      @value_between ||= @category.saldo_for_period_new(@start_day.to_date, @end_day.to_date)
      @value ||= @category.saldo_at_end_of_day(@end_day.to_date)
      @mode ||= :category
    else
      @transfers ||= self.current_user.transfers.find(:all, :order => 'day ASC').map{ |t| {:transfer => t} }
      @mode ||= :transfers
    end
  end

  
  #Set (@transfer or (@start_day, @end_day)) AND (@category or params['current_category']), for proper work <br />
  # Updates div with transfers <br />
  # If exists block is yield with page so you can update the page the way you like <br />
  def render_transfer_table(&block)
    set_variables_for_rendering_transfer_table
    render :update do |page|
      page.replace_html 'transfer-table-div', :partial => 'categories/transfer_table', :locals => {:current_category => @category, :mode => @mode }
      yield page if Kernel.block_given?
    end
  end


  def get_period(period, return_range = false)
    symbol = params[period + "_period"].to_sym
    range = if symbol == :SELECTED
      start = params[period+'_start']
      endt = params[period+'_end']
      Range.new(Date.new(start[:year].to_i, start[:month].to_i, start[:day].to_i), Date.new(endt[:year].to_i, endt[:month].to_i, endt[:day].to_i) )
    else
      Date.calculate(symbol)
    end

    if return_range
      return range
    else
      return range.begin, range.end
    end
  end
  
end
