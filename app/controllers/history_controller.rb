class HistoryController < ApplicationController

  protected

  def find_currencies_for_user
    @currencies = Currency.for_user(self.current_user)
  end


  def find_newest_exchanges
    @exchanges = @currencies.combination(2).map{|a,b| @current_user.exchanges.newest.for_currencies(a,b).find(:first, :include => [:left_currency, :right_currency])}
    @exchanges.compact!
  end


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
    @category ||= self.current_user.categories.find(params[:current_category]) if params[:current_category]
    @include_subcategories = params[:include_subcategories] if params[:include_subcategories]
  end


  def set_start_end_days
    @start_day ||= @transfer.day.beginning_of_month if @transfer
    @end_day ||= @transfer.day.end_of_month if @transfer
    @start_day ||= @range.begin if @range
    @end_day ||= @range.end if @range
  end


  def set_transfers_and_values
    if @category
      @include_subcategories = !!@include_subcategories
      @transfers ||= @category.transfers_with_saldo_for_period_new(@start_day.to_date , @end_day.to_date, @include_subcategories)
      @value_between ||= @category.saldo_for_period_new(@start_day.to_date, @end_day.to_date, :show_all_currencies, @include_subcategories)
      @value ||= @category.saldo_at_end_of_day(Date.today.to_date, :show_all_currencies, @include_subcategories)
      @mode ||= :category
    else
      @transfers ||= self.current_user.transfers.find(:all, :order => 'day ASC', :conditions => ['day >= ? AND day <= ?', @start_day, @end_day]).map{ |t| {:transfer => t} }
      @mode ||= :transfers
    end
  end


  #Set (@transfer or (@start_day, @end_day)) AND (@category or params['current_category']), for proper work <br />
  # Updates div with transfers <br />
  # If exists block is yield with page so you can update the page the way you like <br />
  def render_transfer_table(&block)
    set_variables_for_rendering_transfer_table
    render :update do |page|
      page.replace_html 'transfer-table-div', :partial => 'categories/transfer_table', :locals => {
        :current_category => @category,
        :mode => @mode,
        :include_subcategories => @include_subcategories
      }
      yield page if Kernel.block_given?
    end
  end

end
