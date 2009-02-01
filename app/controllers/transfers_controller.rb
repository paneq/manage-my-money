class TransfersController < ApplicationController

  require 'hash'
  include ActionView::Helpers::ActiveRecordHelper
  
  layout 'main'
  before_filter :login_required
  before_filter :check_perm_for_transfer , :only => [:show_details, :hide_details, :show , :edit_with_items, :destroy]


  # TODO: Refactor
  def index
    create_empty_transfer
    options = {:order => 'day ASC, id ASC'}.merge case self.current_user.transaction_amount_limit_type
    when :transaction_count :
        { :limit => self.current_user.transaction_amount_limit_value, :order => 'day DESC, id DESC', :reverse => true}
    when :week_count
      start_day = (self.current_user.transaction_amount_limit_value - 1).weeks.ago.to_date.beginning_of_week
      end_day = Date.today.end_of_week
      {:conditions => ['day >= ? AND day <= ?', start_day, end_day]}
    when :actual_month
      range = Date.calculate(:THIS_MONTH)
      {:conditions => ['day >= ? AND day <= ?', range.begin, range.end]}
    when :actual_and_last_month
      start_day = Date.calculate_start(:LAST_MONTH)
      end_day = Date.calculate_end(:THIS_MONTH)
      {:conditions => ['day >= ? AND day <= ?', start_day, end_day]}
    else
      {}
    end
    @transfers = self.current_user.transfers.find(:all, options.block(:reverse)).map{ |t| {:transfer => t} }
    @transfers.reverse! if options[:reverse]
  end


  def search    
    @transfers = self.
      current_user.
      transfers.
      find(:all, :order => 'day ASC, id ASC', :conditions => conditions ).
      map { |t| {:transfer => t} }
      
    respond_to do |format|
      format.html {}
      format.js {render_transfer_table}
    end
  end


  # remote
  # TODO: sprawdzenie czy kategorie i waluty naleza do usera
  def quick_transfer
    data = params['data'].to_hash
    @transfer = Transfer.new(data.pass('description', 'day(1i)', 'day(2i)','day(3i)'))
    @transfer.user = self.current_user
    
    ti1 = TransferItem.new(data.pass('description','category_id', 'currency_id', 'value'))
    ti2 = TransferItem.new(data.pass('description', 'currency_id'))
    ti2.value = -1* ti1.value
    ti2.category = self.current_user.categories.find(data['from_category_id'])
    @transfer.transfer_items << ti2 << ti1
    
    if @transfer.save
      render_transfer_table do |page|
        page.replace_html 'form-for-transfer-quick', :partial=>'transfers/quick_transfer', :locals => { :current_category => @category }
      end
    else
      # TODO: change it so there will be a notice that something went wrong
      where = 'quick-transfers'
      render :update do |page|
        page.insert_html :bottom , where , :partial => '' , :object => @transfer
      end
    end
  end


  #remote
  def show_details
    render :update do |page|
      page.hide "show-details-button-#{@transfer.id}"
      page.insert_html :bottom, "transfer-in-category-#{@transfer.id}", :partial => 'transfer_details', :object => @transfer, :locals => {:current_category_id => params[:current_category]}
    end
  end

  
  #remote
  def hide_details
    render :update do |page|
      page.remove "transfer-details-id-#{@transfer.id}"
      page.show "show-details-button-#{@transfer.id}"
    end
  end


  ############################
  # @author: Robert Pankowecki
  # half-remote
  # currently not in use
  # currently i do not know how to make it working
  def add_form_error (error)
    render :update do |page|
      page.remove 'error_in_form'
      page.insert_html :bottom, 'form_erros', :partial=>'error_in_form', :object => error
    end
  end


  def edit
    set_current_category
    @transfer = self.current_user.transfers.find_by_id(params[:id])
    respond_to do |format|
      format.html {}
      format.js do
        render :update do |page|
          page.replace_html "transfer-in-category-#{@transfer.id}", :partial => 'transfers/full_transfer', :locals => { :current_category => @category , :transfer => @transfer, :embedded => true}
        end
      end
    end
  end


  def update
    params[:transfer][:existing_transfer_items_attributes] ||= {}
    @transfer = self.current_user.transfers.find_by_id(params[:id])
    if @transfer.update_attributes(params[:transfer])
      respond_to do |format|
        format.html {}
        format.js do
          render_transfer_table do |page|
            if @category && @category.transfers.find_by_id(@transfer.id)
              #same code as show_details but i could not move it into method and i do not know why.
              page.hide "show-details-button-#{@transfer.id}"
              page.insert_html :bottom, "transfer-in-category-#{@transfer.id}", :partial => 'transfer_details', :object => @transfer, :locals => {:current_category_id => params[:current_category]}
            end
          end
        end
      end
    else
      respond_to do |format|
        format.html {}
        format.js do
          render :update do |page|
            page.replace_html "transfer-errors-#{@transfer.id}", error_messages_for(:transfer, :message => nil)
            @transfer.transfer_items.each do |ti|
              if ti.valid?
                page.replace_html "transfer-item-errors-#{ti.error_id}", ''
              else
                page.replace_html "transfer-item-errors-#{ti.error_id}", error_messages_for(:transfer_item, :object => ti, :message => nil, :header_message => nil, :id =>'small', :class => 'smallerror')
              end
            end
          end
        end #format.js
      end
    end
  end


  def create
    @transfer = Transfer.new(params[:transfer])
    @transfer.user = self.current_user
    if @transfer.save
      respond_to do |format|
        format.html {}
        format.js do
          render_transfer_table do |page|
            create_empty_transfer
            page.replace_html 'form-for-transfer-full', :partial=>'transfers/full_transfer', :locals => {:current_category => @category, :embedded => true, :transfer => @transfer}
          end
        end
      end
    else
      respond_to do |format|
        format.html {}
        format.js do
          render :update do |page|
            page.replace_html 'transfer-errors', error_messages_for(:transfer, :message => nil)
            @transfer.transfer_items.each do |ti|
              if ti.valid?
                page.replace_html "transfer-item-errors-#{ti.error_id}", ''
              else
                page.replace_html "transfer-item-errors-#{ti.error_id}", error_messages_for(:transfer_item, :object => ti, :message => nil, :header_message => nil, :id =>'small', :class => 'smallerror')
              end
            end
          end
        end #format.js

      end
    end
  end


  def destroy
    # TODO: if else ??
    @transfer.destroy
    respond_to do |format|
      format.html do
        flash[:notice] = 'Transfer został usunięty'
        redirect_to :action => 'show', :controller => 'categories', :id => session[:category_id]
      end
      format.js { render_transfer_table }
    end
  end

  
  private
  
  def check_perm_for_transfer
    @transfer = Transfer.find(params[:id])
    if @transfer.user.id != self.current_user.id
      flash[:notice] = 'You do not have permission to view this transfer!'
      @transfer = nil
      redirect_to :action => :index, :controller => :categories
      return
      #why doesn't it work ? There is no flash ?
    end
  end


  def conditions
    set_current_category
    condition = 'day >= ? AND day <= ?'
    @range = get_period('transfer_day', true)

    parameters = [condition, @range.begin, @range.end]

    #searching for transfers connected via items to one category
    if @category
      parameters.first += 'AND category_id IN (?)'
      parameters << if params[:subcategories]
        @category.self_and_descendants().map {|c| c.id} #table of subcategories ids
      else
        [@category.id] #table with category id
      end
    end

    return parameters
  end #conditions method

end
