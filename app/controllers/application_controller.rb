# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  #include ExceptionNotifiable
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
  helper :all

  
  protected

  
  def ssl_required?
    SSL_REQUIRED
  end

  def ssl_allowed?
    SSL_ALLOWED
  end

  def extract_form_id
    params[:form_id]
  end

  def extract_form_errors_id
    extract_form_id + 'errors'
  end

  def get_period(period, return_range = false)
    symbol = params[period + "_period"].to_sym
    range = if symbol == :SELECTED
      Range.new(from_hash(params[period+'_start']), from_hash(params[period+'_end']))
    else
      Date.calculate(symbol)
    end

    if return_range
      return range
    else
      return range.begin, range.end, symbol
    end
  end


  def get_period_range(period)
    get_period(period, true)
  end


  private

  
  # FIXME: To model && write tests
  def from_hash(hash)
    date = Date.today
    begin
      date = Date.new(hash[:year].to_i, hash[:month].to_i, hash[:day].to_i)
    rescue
      begin
        date = Date.new(hash[:year].to_i, hash[:month].to_i, 1)
        date = date.end_of_month
      rescue
      end
    end
    date
  end

end
