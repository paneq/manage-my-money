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
    @include_subcategories ||= params[:include_subcategories] if params[:include_subcategories]
  end


  def set_start_end_days
    @start_day ||= @transfer.day.beginning_of_month if @transfer
    @end_day ||= @transfer.day.end_of_month if @transfer

    @start_day ||= @range.begin if @range
    @end_day ||= @range.end if @range

    @range ||= Range.new(@start_day, @end_day)
  end


  def set_transfers_and_values
    if @category
      @include_subcategories = !!@include_subcategories
      range_or_number = @number || @range
      unless @transfers
        @transfers, @value_between = @category.transfers_with_saldo(:default, @include_subcategories, range_or_number)
      end
      @value ||= @category.saldo_at_end_of_day(Date.today, :default, @include_subcategories)
    else
      @transfers ||= self.current_user.transfers.find(:all, :order => 'day ASC', :conditions => ['day >= ? AND day <= ?', @start_day, @end_day])
    end
  end


  #Set (@transfer or (@start_day, @end_day) or @range) AND (@category or params['current_category']), for proper work <br />
  # Updates div with transfers <br />
  # If exists block is yield with page so you can update the page the way you like <br />
  def render_transfer_table
    set_variables_for_rendering_transfer_table
    partial = if @category
      'categories/transfer_table'
    else
      'transfers/transfer_table'
    end
    render :update do |page|
      page.replace_html 'transfer-table-div', :partial => partial
      yield page if Kernel.block_given?
    end
  end


  def show_transfer_errors
    respond_to do |format|
      format.html {}
      format.js do
        where = extract_form_errors_id() # Cannot be moved into next lines...
        render :update do |page|
          page.replace_html where, error_messages_for(:transfer, :message => nil)
        end
      end #format.js
    end
  end

end
